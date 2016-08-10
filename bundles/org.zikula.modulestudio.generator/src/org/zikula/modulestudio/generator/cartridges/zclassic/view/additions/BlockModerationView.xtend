package org.zikula.modulestudio.generator.cartridges.zclassic.view.additions

import de.guite.modulestudio.metamodel.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class BlockModerationView {
    extension FormattingExtensions = new FormattingExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    def generate(Application it, IFileSystemAccess fsa) {
        if (targets('1.3.x')) {
            val templatePath = getViewPath + 'block/'
            var fileName = 'moderation.tpl'
            if (!shouldBeSkipped(templatePath + fileName)) {
                if (shouldBeMarked(templatePath + fileName)) {
                    fileName = 'moderation.generated.tpl'
                }
                fsa.generateFile(templatePath + fileName, displayTemplateLegacy)
            }
        } else {
            val templatePath = getViewPath + 'Block/'
            var fileName = 'moderation.html.twig'
            if (!shouldBeSkipped(templatePath + fileName)) {
                if (shouldBeMarked(templatePath + fileName)) {
                    fileName = 'moderation.generated.html.twig'
                }
                fsa.generateFile(templatePath + fileName, displayTemplate)
            }
        }
    }

    def private displayTemplateLegacy(Application it) '''
        {* Purpose of this template: show moderation block *}
        {if count($moderationObjects) gt 0}
            <ul>
            {foreach item='modItem' from=$moderationObjects}
                <li><a href="{modurl modname='«appName»' type='admin' func='view' ot=$modItem.objectType workflowState=$modItem.state}" class="z-bold">{$modItem.message}</a></li>
            {/foreach}
            </ul>
        {/if}
    '''

    def private displayTemplate(Application it) '''
        {# Purpose of this template: show moderation block #}
        {% if moderationObjects|length > 0 %}
            <ul>
            {% for modItem in moderationObjects %}
                {% set itemObjectType = modItem.objectType|lower %}
                <li><a href="{{ path('«appName.formatForDB»_' ~ itemObjectType ~ '_adminview', { workflowState: modItem.state }) }}" class="bold">{{ modItem.message }}</a></li>
            {% endfor %}
            </ul>
        {% endif %}
    '''
}