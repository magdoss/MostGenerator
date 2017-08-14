package org.zikula.modulestudio.generator.cartridges.zclassic.controller

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.Entity
import de.guite.modulestudio.metamodel.EntityTreeType
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class MenuLinksHelperFunctions {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions
    extension ModelExtensions = new ModelExtensions
    extension Utils = new Utils

    def generate(Application it) '''
        «menuLinksBetweenControllers»

        «FOR entity : getAllEntities.filter[hasViewAction]»
            «entity.menuLinkToViewAction»
        «ENDFOR»
        «IF needsConfig»
            if ($routeArea == 'admin' && $this->permissionApi->hasPermission($this->getBundleName() . '::', '::', ACCESS_ADMIN)) {
                $links[] = [
                    'url' => $this->router->generate('«appName.formatForDB»_config_config'),
                    'text' => «translate('Configuration')»,
                    'title' => «translate('Manage settings for this application')»,
                    'icon' => 'wrench'
                ];
            }
        «ENDIF»
    '''

    def private menuLinkToViewAction(Entity it) '''
        if (in_array('«name.formatForCode»', $allowedObjectTypes)
            && $this->permissionApi->hasPermission($this->getBundleName() . ':«name.formatForCodeCapital»:', '::', $permLevel)) {
            $links[] = [
                'url' => $this->router->generate('«application.appName.formatForDB»_«name.formatForDB»_' . $routeArea . 'view'«IF tree != EntityTreeType.NONE», ['tpl' => 'tree']«ENDIF»),
                'text' => «application.translate(nameMultiple.formatForDisplayCapital)»,
                'title' => «application.translate(nameMultiple.formatForDisplayCapital + ' list')»
            ];
        }
    '''

    def private menuLinksBetweenControllers(Application it) '''
        if (LinkContainerInterface::TYPE_ADMIN == $type) {
            if ($this->permissionApi->hasPermission($this->getBundleName() . '::', '::', ACCESS_READ)) {
                $links[] = [
                    'url' => $this->router->generate('«appName.formatForDB»_«getLeadingEntity.name.formatForDB»_«getLeadingEntity.getPrimaryAction»'),
                    'text' => «translate('Frontend')»,
                    'title' => «translate('Switch to user area.')»,
                    'icon' => 'home'
                ];
            }
        } else {
            if ($this->permissionApi->hasPermission($this->getBundleName() . '::', '::', ACCESS_ADMIN)) {
                $links[] = [
                    'url' => $this->router->generate('«appName.formatForDB»_«getLeadingEntity.name.formatForDB»_admin«getLeadingEntity.getPrimaryAction»'),
                    'text' => «translate('Backend')»,
                    'title' => «translate('Switch to administration area.')»,
                    'icon' => 'wrench'
                ];
            }
        }
    '''

    def private translate(Application it, String text) '''$this->__('«text»'«IF !isSystemModule», '«appName.formatForDB»'«ENDIF»)'''
}
