# encoding: utf-8

###############################################3
## wiki(text) squads reader for football.db


##
#
# todo: add captain flag  e.g. (c)
# todo: parse birth date too
# todo: parse coach tooo


require 'logutils'


class Squad   # Squad record

  attr_accessor :players

  def initialize
    @players = []
  end

  POS_TO_I = {
      'GK' => 1,   # goalkeeper
      'DF' => 2,   # defender
      'MF' => 3,   # midfielder
      'FW' => 4,   # forward
      nil  => 5    # unknown pos (let it go last)
  }

  def cmp_by_pos( l, r )
    res =  POS_TO_I[ l.pos] <=> POS_TO_I[ r.pos ]  # pass 1: sort by pos (e.g. GK,DF,MF,FW,nil)
    
    # note: make sure no values are present (e.g. not nil)
    if res == 0 && l.no && r.no
      res =  l.no <=> r.no         # pass 2: sort by (shirt) no (e.g. 1,2,3.etc.)
    end
    res
  end


  def to_rec( opts={} )
    
    sort_by_pos =  opts[:sort] ? true : false

    if sort_by_pos
      players = @players.sort { |l,r| cmp_by_pos( l,r ) }
    else
      players = @players
    end

    last_pos = nil


    buf = ''
    buf << "#############################\n"
    buf << "#  #{@players.size} players\n"
    buf << "\n"

    players.each do |p|
      if last_pos && last_pos != p.pos   # add newline break for new pos (GK,DF,MF,FW,etc.)
        buf << "\n"
      end

      buf << p.to_rec
      buf << "\n"
      
      last_pos = p.pos
    end
    buf
  end

end # class Squad


class Player   # Player record
  
  attr_accessor :no, :pos,
                :name, :name_wiki,
                :club, :club_wiki,
                :clubnat,
                :caps

  def initialize
  end

  def to_rec
    no_str   = no.nil?    ? '-' : "(#{no})"
    caps_str = caps.nil?  ? '-' : caps.to_s

    buf = ''
    buf << "%4s  "   % no_str
    buf << "%2s  "   % "#{pos}"
    buf << "%-33s  " % "#{name}"
    buf << '## '
    buf << "%4s, "   % caps_str
    buf << "#{club} "
    buf << "(#{clubnat})"  if clubnat
    buf
  end

end # class Player


class SquadsBuilder

  include LogUtils::Logging

  attr_accessor :include_path, :output_path

  def initialize( include_path, opts = {} )
    @include_path = include_path
    @output_path  = './'  # set default to current directory
  end


  ###
  ## todo: fix? - strip spaces from link and title
  ##   spaces possible? strip in ruby later e.g. use strip - why? why not?

  WIKI_LINK_PATTERN = %q{
    \[\[
      (?<link>[^|\]]+)     # everything but pipe (|) or bracket (])
      (?:
        \|
        (?<title>[^\]]+)
      )?                   # optional wiki link title
    \]\]
  }

  FS_START_REGEX  = /fs start/
  FS_PLAYER_REGEX = /fs player/
  FS_END_REGEX    = /fs end/

  FS_PLAYER_NAME_REGEX = /\b
                          name=#{WIKI_LINK_PATTERN}
                         /x

  FS_PLAYER_CLUB_REGEX = /\b
                          club=#{WIKI_LINK_PATTERN}
                         /x

  FS_PLAYER_CLUBNAT_REGEX = /\b
                          clubnat=
                            (?<clubnat>[A-Z]{3})
                             \b/x


  ## todo:
  ##  check for empty (no number) e.g.   no=-      -- see world cup squads 1930
  ##  check for multiple numbers e.g.  no=9 & 8    -- see world cup squads 1930
  FS_PLAYER_NO_REGEX = /\b
                          no=\s*
                           (?<no>[0-9]+)
                        \b/x

  ## todo:
  ##  check for empty (no caps) e.g.   caps=-      -- see world cup squads 1930
  FS_PLAYER_CAPS_REGEX = /\b
                          caps=
                           (?<caps>[0-9]+)
                          \b/x

  FS_PLAYER_POS_REGEX = /\b
                           pos=
                           (?<pos>[A-Z]{2,})
                          \b/x


  def read( name, opts={} )

    ## e.g. world cup 1930 to 1950 has no player nos (allows to skip player nos - will all be nil)
    skip_player_no = opts[:skip_player_no].nil? ? false : opts[:skip_player_no]

    path = "#{include_path}/#{name}.txt"

    @squads = []
    squad  = nil   ## current squad

    File.readlines( path ).each_with_index do |line,lineno|  # note: starts w/ 0 (use lineno+1)

      ## clean line
      ##   remove {{0}}  - todo: find out what is it good for? what does it mean?
      ##   remove '''
      ###  e.g.
      ##    no='''{{0}}1'''    or no={{0}}1
      ##      becomes
      ##     no=1              or no=1

      line = line.gsub( '{{0}}}', '' )  ## remove {{0}}  empty infoset? or what does it mean? check/find out
      line = line.gsub( "'''", '' )   ## remove bold marker


      if line =~ FS_START_REGEX
        logger.info "start squads block (line #{lineno+1})"
        squad = Squad.new
      elsif line =~ FS_END_REGEX
        logger.info "end squads block (line #{lineno+1})"
        @squads << squad
      elsif line =~ FS_PLAYER_REGEX
        logger.info "  parse squads player line (line #{lineno+1})"
        
        player = Player.new
        
        md=FS_PLAYER_NAME_REGEX.match( line )
        if md
          h = {}
          # - note: do NOT forget to turn name into symbol for lookup in new hash (name.to_sym)
          md.names.each { |n| h[n.to_sym] = md[n] } # or use match_data.names.zip( match_data.captures ) - more cryptic but "elegant"??

          if h[:title]
            player.name      = h[:title]
            player.name_wiki = h[:link]
          else
            player.name      = h[:link]  # link is also title
            player.name_wiki = h[:link]
          end
        end

        md=FS_PLAYER_CLUB_REGEX.match( line )
        if md
          h = {}
          # - note: do NOT forget to turn name into symbol for lookup in new hash (name.to_sym)
          md.names.each { |n| h[n.to_sym] = md[n] } # or use match_data.names.zip( match_data.captures ) - more cryptic but "elegant"??

          if h[:title]
            player.club      = h[:title]
            player.club_wiki = h[:link]
          else
            player.club      = h[:link]  # link is also title
            player.club_wiki = h[:link]
          end
        end

        md=FS_PLAYER_CLUBNAT_REGEX.match( line )
        player.clubnat = md[:clubnat]  if md

        unless skip_player_no
          md=FS_PLAYER_NO_REGEX.match( line )
          player.no = md[:no].to_i  if md     # note: convert string to number (integer)
        end

        md = FS_PLAYER_CAPS_REGEX.match( line )
        player.caps = md[:caps].to_i  if md   # note: convert string to number (integer)

        md = FS_PLAYER_POS_REGEX.match( line )
        player.pos = md[:pos] if md

        logger.info "    #{player.to_rec}"
        squad.players << player
      else
        # skip; do nothing
      end
      
    end
  end  # method read

  def dump
    ## dump squads
    @squads.each_with_index do |squad,i|
      puts "========================"
      # puts " squad ##{i+1}"
      # puts squad.to_rec

      puts " squad ##{i+1} (sorted)"
      puts squad.to_rec( sort: true )
    end
  end
  
  def write( names )

    ##
    ## fix/todo:
    ##   assert that names.size and @squads.size match

    ## dump squads
    @squads.each_with_index do |squad,i|
      name = names[i]
      next if name.nil?   # no more filename? skip squad for now

      path = "#{output_path}/#{name}.txt"

      puts " squad ##{i+1} writing to #{path} (sorted)..."

      File.open( path, 'w' ) do |f|
        f << squad.to_rec( sort: true )
      end
    end
  end  # method write

end  # class SquadsBuilder
