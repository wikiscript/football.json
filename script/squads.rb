# encoding: utf-8

###############################################3
## wiki(text) squads reader for football.db

require 'logutils'


class Squad   # Squad record

  attr_accessor :players

  def initialize
    @players = []
  end

  def to_rec
    buf = ''
    @players.each do |p|
      buf << p.to_rec
      buf << "\n"
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
    buf = ''
    buf << "%4s  "   % "(#{no})"
    buf << "%2s  "   % "#{pos}"
    buf << "%-33s  " % "#{name}"
    buf << '## '
    buf << "%4s "    % "#{caps},"
    buf << "#{club} "
    buf << "(#{clubnat})"  if clubnat
    buf
  end

end # class Player


class SquadsBuilder

  include LogUtils::Logging

  attr_reader :include_path

  def initialize( include_path, opts = {} )
    @include_path = include_path
  end


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

  FS_PLAYER_NO_REGEX = /\b
                          no=
                           (?<no>[0-9]+)
                        \b/x

  FS_PLAYER_CAPS_REGEX = /\b
                          caps=
                           (?<caps>[0-9]+)
                          \b/x

  FS_PLAYER_POS_REGEX = /\b
                           pos=
                           (?<pos>[A-Z]{2,})
                          \b/x

  def read( name, opts={} )

    path = "#{include_path}/#{name}.wiki"

    squads = []
    squad  = nil   ## current squad

    File.readlines( path ).each_with_index do |line,lineno|  # note: starts w/ 0 (use lineno+1)

      if line =~ FS_START_REGEX
        logger.info "start squads block (line #{lineno+1})"
        squad = Squad.new
      elsif line =~ FS_END_REGEX
        logger.info "end squads block (line #{lineno+1})"
        squads << squad
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

        md=FS_PLAYER_NO_REGEX.match( line )
        player.no = md[:no]  if md

        md = FS_PLAYER_CAPS_REGEX.match( line )
        player.caps = md[:caps]  if md

        md = FS_PLAYER_POS_REGEX.match( line )
        player.pos = md[:pos] if md

        logger.info "    #{player.to_rec}"
        squad.players << player
      else
        # skip; do nothing
      end
      
    end

    ## dump squads
    squads.each_with_index do |squad,i|
      puts "========================"
      puts " squad ##{i+1}"
      puts squad.to_rec
    end

  end  # method read


end  # class SquadsBuilder
