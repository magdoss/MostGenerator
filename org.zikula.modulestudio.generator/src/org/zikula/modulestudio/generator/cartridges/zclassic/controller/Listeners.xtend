package org.zikula.modulestudio.generator.cartridges.zclassic.controller

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.Core
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.Errors
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.FrontController
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.Group
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.Mailer
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.ModuleDispatch
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.ModuleInstaller
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.Page
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.Theme
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.ThirdParty
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.User
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.UserLogin
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.UserLogout
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.UserRegistration
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.Users
import org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener.View
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.WorkflowExtensions

class Listeners {
    @Inject extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions
    @Inject extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    @Inject extension ModelExtensions = new ModelExtensions
    @Inject extension NamingExtensions = new NamingExtensions
    @Inject extension Utils = new Utils
    @Inject extension WorkflowExtensions = new WorkflowExtensions

    FileHelper fh = new FileHelper
    IFileSystemAccess fsa
    Application app
    Boolean isBase

    String listenerPath
    String listenerSuffix

    /**
     * Entry point for persistent event listeners.
     */
    def generate(Application it, IFileSystemAccess fsa) {
        this.fsa = fsa
        this.app = it
        listenerSuffix = (if (targets('1.3.5')) '' else 'Listener') + '.php'

        println('Generating event listener base classes')
        listenerPath = getAppSourceLibPath + 'Listener/Base/'
        isBase = true

        listenerFile('Core', listenersCoreFile)
        listenerFile('FrontController', listenersFrontControllerFile)
        listenerFile('Installer', listenersInstallerFile)
        listenerFile('ModuleDispatch', listenersModuleDispatchFile)
        listenerFile('Mailer', listenersMailerFile)
        listenerFile('Page', listenersPageFile)
        if (targets('1.3.5')) {
            listenerFile('Errors', listenersErrorsFile)
        }
        listenerFile('Theme', listenersThemeFile)
        listenerFile('View', listenersViewFile)
        listenerFile('UserLogin', listenersUserLoginFile)
        listenerFile('UserLogout', listenersUserLogoutFile)
        listenerFile('User', listenersUserFile)
        listenerFile('UserRegistration', listenersUserRegistrationFile)
        listenerFile('Users', listenersUsersFile)
        listenerFile('Group', listenersGroupFile)
        listenerFile('ThirdParty', listenersThirdPartyFile)

        if (generateOnlyBaseClasses) {
            return
        }

        println('Generating event listener implementation classes')
        listenerPath = getAppSourceLibPath + 'Listener/'
        isBase = false

        listenerFile('Core', listenersCoreFile)
        listenerFile('FrontController', listenersFrontControllerFile)
        listenerFile('Installer', listenersInstallerFile)
        listenerFile('ModuleDispatch', listenersModuleDispatchFile)
        listenerFile('Mailer', listenersMailerFile)
        listenerFile('Page', listenersPageFile)
        if (targets('1.3.5')) {
            listenerFile('Errors', listenersErrorsFile)
        }
        listenerFile('Theme', listenersThemeFile)
        listenerFile('View', listenersViewFile)
        listenerFile('UserLogin', listenersUserLoginFile)
        listenerFile('UserLogout', listenersUserLogoutFile)
        listenerFile('User', listenersUserFile)
        listenerFile('UserRegistration', listenersUserRegistrationFile)
        listenerFile('Users', listenersUsersFile)
        listenerFile('Group', listenersGroupFile)
        listenerFile('ThirdParty', listenersThirdPartyFile)
    }

    def private listenerFile(String name, CharSequence content) {
        val filePath = listenerPath + name + listenerSuffix
        if (!app.shouldBeSkipped(filePath)) {
            fsa.generateFile(filePath, content)
        }
    }

    def private listenersCoreFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\CoreListener as BaseCoreListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;
        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for core events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_Core extends «ENDIF»«appName»_Listener_Base_Core
        «ELSE»
        class CoreListener«IF !isBase» extends BaseCoreListener«ENDIF»
        «ENDIF»
        {
            «new Core().generate(it, isBase)»
        }
    '''

    def private listenersFrontControllerFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\FrontControllerListener as BaseFrontControllerListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for frontend controller interaction events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_FrontController extends «ENDIF»«appName»_Listener_Base_FrontController
        «ELSE»
        class FrontControllerListener«IF !isBase» extends BaseFrontControllerListener«ENDIF»
        «ENDIF»
        {
            «new FrontController().generate(it, isBase)»
        }
    '''

    def private listenersInstallerFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\InstallerListener as BaseInstallerListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for module installer events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_Installer extends «ENDIF»«appName»_Listener_Base_Installer
        «ELSE»
        class InstallerListener«IF !isBase» extends BaseInstallerListener«ENDIF»
        «ENDIF»
        {
            «new ModuleInstaller().generate(it, isBase)»
        }
    '''

    def private listenersModuleDispatchFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\ModuleDispatchListener as BaseModuleDispatchListener;
            «ENDIF»
            «IF isBase»
                use ModUtil;
                use Zikula\Core\CoreEvents;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for dispatching modules.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_ModuleDispatch extends «ENDIF»«appName»_Listener_Base_ModuleDispatch
        «ELSE»
        class ModuleDispatchListener«IF !isBase» extends BaseModuleDispatchListener«ENDIF»
        «ENDIF»
        {
            «new ModuleDispatch().generate(it, isBase)»
        }
    '''

    def private listenersMailerFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\MailerListener as BaseMailerListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for mailing events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_Mailer extends «ENDIF»«appName»_Listener_Base_Mailer
        «ELSE»
        class MailerListener«IF !isBase» extends BaseMailerListener«ENDIF»
        «ENDIF»
        {
            «new Mailer().generate(it, isBase)»
        }
    '''

    def private listenersPageFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\PageListener as BasePageListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for page-related events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_Page extends «ENDIF»«appName»_Listener_Base_Page
        «ELSE»
        class PageListener«IF !isBase» extends BasePageListener«ENDIF»
        «ENDIF»
        {
            «new Page().generate(it, isBase)»
        }
    '''

    // obsolete, used for 1.3.5 only
    def private listenersErrorsFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\ErrorsListener as BaseErrorsListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for error-related events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_Errors extends «ENDIF»«appName»_Listener_Base_Errors
        «ELSE»
        class ErrorsListener«IF !isBase» extends BaseErrorsListener«ENDIF»
        «ENDIF»
        {
            «new Errors().generate(it, isBase)»
        }
    '''

    def private listenersThemeFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\ThemeListener as BaseThemeListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for theme-related events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_Theme extends «ENDIF»«appName»_Listener_Base_Theme
        «ELSE»
        class ThemeListener«IF !isBase» extends BaseThemeListener«ENDIF»
        «ENDIF»
        {
            «new Theme().generate(it, isBase)»
        }
    '''

    def private listenersViewFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\ViewListener as BaseViewListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for view-related events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_View extends «ENDIF»«appName»_Listener_Base_View
        «ELSE»
        class ViewListener«IF !isBase» extends BaseViewListener«ENDIF»
        «ENDIF»
        {
            «new View().generate(it, isBase)»
        }
    '''

    def private listenersUserLoginFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\UserLoginListener as BaseUserLoginListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for user login events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_UserLogin extends «ENDIF»«appName»_Listener_Base_UserLogin
        «ELSE»
        class UserLoginListener«IF !isBase» extends BaseUserLoginListener«ENDIF»
        «ENDIF»
        {
            «new UserLogin().generate(it, isBase)»
        }
    '''

    def private listenersUserLogoutFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\UserLogoutListener as BaseUserLogoutListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for user logout events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_UserLogout extends «ENDIF»«appName»_Listener_Base_UserLogout
        «ELSE»
        class UserLogoutListener«IF !isBase» extends BaseUserLogoutListener«ENDIF»
        «ENDIF»
        {
            «new UserLogout().generate(it, isBase)»
        }
    '''

    def private listenersUserFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF isBase»
                «IF hasStandardFieldEntities || hasUserFields»
                    use ModUtil;
                    use ServiceUtil;
                «ENDIF»
            «ELSE»
                use «appNamespace»\Listener\Base\UserListener as BaseUserListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for user-related events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_User extends «ENDIF»«appName»_Listener_Base_User
        «ELSE»
        class UserListener«IF !isBase» extends BaseUserListener«ENDIF»
        «ENDIF»
        {
            «new User().generate(it, isBase)»
        }
    '''

    def private listenersUserRegistrationFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\UserRegistrationListener as BaseUserRegistrationListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for user registration events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_UserRegistration extends «ENDIF»«appName»_Listener_Base_UserRegistration
        «ELSE»
        class UserRegistrationListener«IF !isBase» extends BaseUserRegistrationListener«ENDIF»
        «ENDIF»
        {
            «new UserRegistration().generate(it, isBase)»
        }
    '''

    def private listenersUsersFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\UsersListener as BaseUsersListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler «IF isBase»base«ELSE»implementation«ENDIF» class for events of the Users module.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_Users extends «ENDIF»«appName»_Listener_Base_Users
        «ELSE»
        class UsersListener«IF !isBase» extends BaseUsersListener«ENDIF»
        «ENDIF»
        {
            «new Users().generate(it, isBase)»
        }
    '''

    def private listenersGroupFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\GroupListener as BaseGroupListener;
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;

        «ENDIF»
        /**
         * Event handler implementation class for group-related events.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_Group extends «ENDIF»«appName»_Listener_Base_Group
        «ELSE»
        class GroupListener«IF !isBase» extends BaseGroupListener«ENDIF»
        «ENDIF»
        {
            «new Group().generate(it, isBase)»
        }
    '''

    def private listenersThirdPartyFile(Application it) '''
        «fh.phpFileHeader(it)»
        «IF !targets('1.3.5')»
            namespace «appNamespace»\Listener«IF isBase»\Base«ENDIF»;

            «IF !isBase»
                use «appNamespace»\Listener\Base\ThirdPartyListener as BaseThirdPartyListener;
            «ELSE»
                «IF needsApproval»
                    use «appNamespace»\Util\WorkflowUtil;
                    use ServiceUtil;
                    use Zikula\Collection\Container;
                «ENDIF»
            «ENDIF»
            use Zikula\Core\Event\GenericEvent;
            «IF isBase»
                «IF needsApproval»
                    use Zikula\Provider\AggregateItem;
                «ENDIF»
            «ENDIF»

        «ENDIF»
        /**
         * Event handler implementation class for special purposes and 3rd party api support.
         */
        «IF targets('1.3.5')»
        class «IF !isBase»«appName»_Listener_ThirdParty extends «ENDIF»«appName»_Listener_Base_ThirdParty
        «ELSE»
        class ThirdPartyListener«IF !isBase» extends BaseThirdPartyListener«ENDIF»
        «ENDIF»
        {
            «new ThirdParty().generate(it, isBase)»
        }
    '''
}
