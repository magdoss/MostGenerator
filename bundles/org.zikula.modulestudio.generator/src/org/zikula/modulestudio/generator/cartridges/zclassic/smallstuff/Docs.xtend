package org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff

import de.guite.modulestudio.metamodel.Application
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.documents.License_GPL
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.documents.License_LGPL
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.techdocs.TechComplexity
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.techdocs.TechStructure
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class Docs {

    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension ModelExtensions = new ModelExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    /**
     * Entry point for module documentation.
     */
    def generate(Application it, IMostFileSystemAccess fsa) {
        var fileName = 'CHANGELOG.md'
        fsa.generateFile(fileName, Changelog)

        fileName = 'README.md'
        fsa.generateFile(fileName, ReadmeMarkup)

        val docPath = getAppDocPath
        fileName = 'credits.md'
        fsa.generateFile(docPath + fileName, Credits)

        fileName = 'modulestudio.md'
        fsa.generateFile(docPath + fileName, MostText)

        fileName = 'install.md'
        fsa.generateFile(docPath + fileName, Install)

        if (!isSystemModule) {
            fileName = 'translation.md'
            fsa.generateFile(docPath + fileName, Translation)
        }

        fileName = 'LICENSE'
        fsa.generateFile(getAppLicencePath + fileName, License)

        if (writeModelToDocs) {
            fsa.generateFile(docPath + '/model/.htaccess', htAccessForModel)
        }

        if (generateTechnicalDocumentation) {
            val techDocPath = docPath + '/model/'
            for (language : #['en', 'de']) {
                fileName = 'structure_' + language + '.html'
                fsa.generateFile(techDocPath + fileName, new TechStructure().generate(it, language))

                fileName = 'complexity_' + language + '.html'
                fsa.generateFile(techDocPath + fileName, new TechComplexity().generate(it, language))
            }
        }
    }

    def private Credits(Application it) '''
        # CREDITS

    '''

    def private Changelog(Application it) '''
        # CHANGELOG

        Changes in «appName» «version»
    '''

    def private MostText(Application it) '''
        # MODULESTUDIO
        
        This module has been generated by ModuleStudio «msVersion», a model-driven solution
        for creating web applications for the Zikula Application Framework.

        If you are interested in a new level of Zikula development, visit «msUrl».
    '''

    def private Install(Application it) '''
        # INSTALLATION INSTRUCTIONS

        «IF needsComposerInstall»
            0. If the application's root folder does not contain a `vendor/` folder yet, run `composer install --no-dev` to install dependencies.
        «ENDIF»
        «IF isSystemModule»
            1. Copy «appName» into your `system` directory. Afterwards you should have a folder named `«relativeAppRootPath»/Resources`.
        «ELSE»
            1. Copy «appName» into your `modules` directory. Afterwards you should have a folder named `«relativeAppRootPath»/Resources`.
        «ENDIF»
        2. Initialize and activate «appName» in the extensions administration.
        «IF hasUploads»
            3. Move or copy the directory `Resources/userdata/«appName»/` to `/«IF targets('2.0')»web/uploads«ELSE»userdata«ENDIF»/«appName»/`.
               Note this step is optional as the install process can create these folders, too.
            4. Make the directory `/«IF targets('2.0')»web/uploads«ELSE»userdata«ENDIF»/«appName»/` writable including all sub folders.
        «ENDIF»

        For questions and other remarks visit our homepage «url».

        «ReadmeFooter»
    '''

    def private Translation(Application it) '''
        # TRANSLATION INSTRUCTIONS

        To create a new translation follow the steps below:

        1. First install the module like described in the `install.md` file.
        2. Open a console and navigate to the Zikula root directory.
        3. Execute this command replacing `en` by your desired locale code:

        `php «IF targets('2.0')»bin«ELSE»app«ENDIF»/console translation:extract en --bundle=«appName» --enable-extractor=jms_i18n_routing --output-format=po«IF generateTagSupport» --exclude-dir=TaggedObjectMeta«ENDIF»`

        You can also use multiple locales at once, for example `de fr es`.

        4. Translate the resulting `.po` files in `«relativeAppRootPath»/Resources/translations/` using your favourite Gettext tooling.

        Note you can even include custom views in `app/Resources/«appName»/views/` and JavaScript files in `app/Resources/«appName»/public/js/` like this:

        `php «IF targets('2.0')»bin«ELSE»app«ENDIF»/console translation:extract en --bundle=«appName» --enable-extractor=jms_i18n_routing --output-format=po«IF generateTagSupport» --exclude-dir=TaggedObjectMeta«ENDIF» --dir=./«relativeAppRootPath» --dir=./app/Resources/«appName»`

        For questions and other remarks visit our homepage «url».

        «ReadmeFooter»
    '''

    def private ReadmeFooter(Application it) '''
        «author»«IF email != ""» («email»)«ENDIF»
        «IF url != ""»«url»«/*«ELSE»«msUrl»*/»«ENDIF»
    '''

    def ReadmeMarkup(Application it) '''
        # «appName» «version»

        «appDescription»

        This module is intended for being used with Zikula «targetSemVer(true)» and later.

        For questions and other remarks visit our homepage «url».

        «ReadmeFooter»
    '''

    def private License(Application it) '''
        «IF license == 'http://www.gnu.org/licenses/lgpl.html GNU Lesser General Public License'
          || license == 'GNU Lesser General Public License'
          || license == 'Lesser General Public License'
          || license == 'LGPL'»
            «new License_LGPL().generate(it)»
        «ELSEIF license == 'http://www.gnu.org/copyleft/gpl.html GNU General Public License'
          || license == 'GNU General Public License'
          || license == 'General Public License'
          || license == 'GPL'»
            «new License_GPL().generate(it)»
        «ELSE»
            Please enter your license text here.
        «ENDIF»
    '''

    def private htAccessForModel(Application it) '''
        # «generatedBy(it, timestampAllGeneratedFiles, versionAllGeneratedFiles)»
        # ------------------------------------------------------------
        # Purpose of file: block any web access to unallowed files
        # stored in this directory
        # ------------------------------------------------------------

        # Apache 2.2
        <IfModule !mod_authz_core.c>
            Deny from all
        </IfModule>

        # Apache 2.4
        <IfModule mod_authz_core.c>
            Require all denied
        </IfModule>
    '''
}
