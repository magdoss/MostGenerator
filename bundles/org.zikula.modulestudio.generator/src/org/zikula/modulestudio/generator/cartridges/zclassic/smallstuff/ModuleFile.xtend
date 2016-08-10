package org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff

import de.guite.modulestudio.metamodel.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class ModuleFile {

    extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    FileHelper fh = new FileHelper

    def generate(Application it, IFileSystemAccess fsa) {
        if (targets('1.3.x')) {
            return
        }
        generateClassPair(fsa, getAppSourceLibPath + appName + '.php',
            fh.phpFileContent(it, moduleBaseImpl), fh.phpFileContent(it, moduleInfoImpl)
        )
    }

    def private moduleBaseImpl(Application it) '''
        namespace «appNamespace»\Base;

        «IF isSystemModule»
            use Zikula\Bundle\CoreBundle\Bundle\AbstractCoreModule;
        «ELSE»
            use Zikula\Core\AbstractModule;
        «ENDIF»

        /**
         * Module base class.
         */
        class «appName» extends Abstract«IF isSystemModule»Core«ENDIF»Module
        {
        }
    '''

    def private moduleInfoImpl(Application it) '''
        namespace «appNamespace»;

        use «appNamespace»\Base\«appName» as Base«appName»;

        /**
         * Module implementation class.
         */
        class «appName» extends Base«appName»
        {
            // custom enhancements can go here
        }
    '''
}