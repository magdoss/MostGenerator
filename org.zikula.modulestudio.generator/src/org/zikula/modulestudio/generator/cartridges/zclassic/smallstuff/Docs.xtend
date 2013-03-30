package org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.documents.DeveloperHints
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.documents.License_GPL
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.documents.License_LGPL
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class Docs {
    @Inject extension FormattingExtensions = new FormattingExtensions()
    @Inject extension ModelExtensions = new ModelExtensions()
    @Inject extension NamingExtensions = new NamingExtensions()
    @Inject extension Utils = new Utils()

    /**
     * Entry point for module documentation.
     */
    def generate(Application it, IFileSystemAccess fsa) {
        fsa.generateFile(getAppSourcePath + 'CHANGELOG.md', Changelog)
        fsa.generateFile(getAppSourcePath + 'README.md', ReadmeMarkup)
        val docPath = getAppDocPath
        fsa.generateFile(docPath + 'credits.md', Credits)
        fsa.generateFile(docPath + 'developers.md', new DeveloperHints().generate(it))
        fsa.generateFile(docPath + 'doctrine.md', DoctrineHints)
        fsa.generateFile(docPath + 'modulestudio.md', MostText)
        fsa.generateFile(docPath + 'install.md', Install)
        fsa.generateFile(docPath + 'license.md', License)
    }

    def private Credits(Application it) '''
        CREDITS
        =======

    '''

    def private Changelog(Application it) '''
        CHANGELOG
        =========

        Changes in «appName» «version»
    '''


    def private DoctrineHints(Application it) '''
        NOTES ON USING DOCTRINE 2
        =========================

        Please note that you should not use print_r() for debugging Doctrine 2 entities.
        The reason for that is that these objects contain too many references which will
        result in a very huge output.

        Instead use the Doctrine\Common\Util\Debug::dump($data) method which reduces
        the output to reasonable information.
        
        Read more about Doctrine at http://docs.doctrine-project.org/projects/doctrine-orm/en/latest/index.html
    '''


    def private MostText(Application it) '''
        MODULESTUDIO
        ============
        
        This module has been generated by ModuleStudio «msVersion», a model-driven solution
        for creating web applications for the Zikula Application Framework.

        If you are interested in a new level of Zikula development, visit «msUrl».
    '''

    def private Install(Application it) '''
        INSTALLATION INSTRUCTIONS
        =========================

        1) Copy «appName» to your modules folder.
        2) Initialize and activate «appName» in the modules administration.
        «IF !targets('1.3.5')»
            3) Move or copy the directory `Resources/userdata/«appName»/` to `/userdata/«appName»/`.
               Note this step is optional as the install process can create these folders, too.
            «IF hasUploads»
                4) Make the directory `/userdata/«appName»/` writable including all sub folders.
            «ENDIF»
        «ELSE»
            «IF hasUploads»
                3) Make the directory `/userdata/«appName»/` writable including all sub folders.
            «ENDIF»
        «ENDIF»

        For questions and other remarks visit our homepage «url».

        «ReadmeFooter»
    '''

    def private ReadmeFooter(Application it) '''
        «author»«IF email != ""» («email»)«ENDIF»
        «IF url != ""»«url»«/*«ELSE»«msUrl»*/»«ENDIF»
    '''

    def ReadmeMarkup(Application it) '''
        «vendor.formatForDisplay»\«appName» «version»
        ===========================

        «IF documentation !== null && documentation != ''»
            «documentation.replaceAll("'", "\\'")»
        «ELSE»
            «vendor.formatForDisplay»\«appName» module generated by ModuleStudio «msVersion».
        «ENDIF»

        «IF targets('1.3.5')»
            This module is intended for being used with Zikula 1.3.5.
        «ELSE»
            This module is intended for being used with Zikula 1.3.6 and later.
        «ENDIF»

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
}
