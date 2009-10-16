require 'rake'
require '/Users/luddep/Code/cappuccino/common'
require 'objective-j'
require 'objective-j/bundletask'
 
 
$ENVIRONMENT_PRODUCT = File.join($ENVIRONMENT_FRAMEWORKS_DIR, 'LPKit')
$BUILD_PATH = File.join($BUILD_DIR, $CONFIGURATION, 'LPKit')
 
ObjectiveJ::BundleTask.new(:LPKit) do |t|
    t.name          = 'LPKit'
    t.identifier    = 'com.luddep.LPKit'
    t.version       = '0.1'
    t.author        = 'Ludwig Pettersson'
    t.email         = 'luddep@gmail.com'
    t.summary       = 'BlendKit classes for Cappuccino'
    t.sources       = FileList['*.j']
    t.resources     = FileList['Resources/*'].to_a
    t.license       = ObjectiveJ::License::LGPL_v2_1
    t.build_path    = $BUILD_PATH
    t.flag          = '-DDEBUG' if $CONFIGURATION == 'Debug'
    t.flag          = '-O' if $CONFIGURATION == 'Release'
    t.type          = ObjectiveJ::Bundle::Type::Framework
end
 
#Framework in environment directory
file_d $ENVIRONMENT_PRODUCT => [:LPKit] do
    cp_r(File.join($BUILD_PATH, '.'), $ENVIRONMENT_PRODUCT)
end
 
task :build => [:LPKit, $ENVIRONMENT_PRODUCT]
 
CLOBBER.include($ENVIRONMENT_PRODUCT)