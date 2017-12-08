package org.zikula.modulestudio.generator.cartridges.zclassic.view.additions

import de.guite.modulestudio.metamodel.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions

class BlockDetailView {

    extension ControllerExtensions = new ControllerExtensions
    extension NamingExtensions = new NamingExtensions

    def generate(Application it, IFileSystemAccess fsa) {
        if (!generateDetailBlock || !hasDisplayActions) {
            return
        }
        val templatePath = getViewPath + 'Block/'
        val templateExtension = '.html.twig'
        var fileName = 'item_modify' + templateExtension
        if (!shouldBeSkipped(templatePath + fileName)) {
            if (shouldBeMarked(templatePath + fileName)) {
                fileName = 'item_modify.generated' + templateExtension
            }
            fsa.generateFile(templatePath + fileName, editTemplate)
        }
    }

    def private editTemplate(Application it) '''
        {# Purpose of this template: Edit block for generic item detail view #}
        {{ form_row(form.objectType) }}
        {{ form_row(form.id) }}
        {{ form_row(form.customTemplate) }}
    '''
}
