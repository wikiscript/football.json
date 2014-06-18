
require './scripts/squads'


task :default => :build


task :build  do
  puts 'hello from squad reader/builder'

  b = SquadsBuilder.new( './world-cup' )

  [1930,2014].each do |year|
    config = YAML.load_file( "./config/world_cup_#{year}.yml" )
    pp config

    page  = config['page']
    teams = config['teams'] # filenames for teams (note: MUST match order in page)

    b.read( page )
    ## b.dump

    outpath = "./o/#{year}"
    mkdir_p( outpath ) unless Dir.exists?( outpath )

    b.output_path = outpath
    b.write( teams )
  end

end

