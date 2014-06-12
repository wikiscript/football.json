
require './scripts/squads'


task :default => :build


task :build  do
  puts 'hello from squad reader/builder'

  b = SquadsBuilder.new( './world-cup' )

  b.read( '2014_FIFA_World_Cup_squads' )
  ## b.dump

  # filenames for teams
  teams = [
    'br-brazil',   # Group A
    'cm-cameroon',
    'hr-croatia',
    'mx-mexico', 
    'au-australia', # Group B
    'cl-chile',
    'nl-netherlands',
    'es-espana',
    'co-colombia',  # Group C
    'gr-greece',
    'ci-cote-d-ivoire',
    'jp-japan',
    'cr-costa-rica', # Group D
    'en-england',
    'it-italy',
    'uy-uruguay',
    'ec-ecuador', # Group E
    'fr-france',
    'hn-honduras',
    'ch-switzerland',
    'ar-argentina', # Group F
    'ba-bosnia-herzegovina',
    'ir-iran',
    'ng-nigeria',
    'de-deutschland', # Group G
    'gh-ghana',
    'pt-portugal',
    'us-united-states',
    'dz-algeria', # Group H
    'be-belgium',
    'ru-russia',
    'kr-south-korea'
  ]

  mkdir( './o' ) unless Dir.exists?( './o' )

  b.write( teams )

end

