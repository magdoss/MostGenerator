package org.zikula.modulestudio.generator.cartridges.zclassic.view.additions

import de.guite.modulestudio.metamodel.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class SearchView {

    extension FormattingExtensions = new FormattingExtensions
    extension ModelExtensions = new ModelExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    def generate(Application it, IFileSystemAccess fsa) {
        val templatePath = getViewPath + (if (targets('1.3.x')) 'search' else 'Search') + '/'
        val templateExtension = if (targets('1.3.x')) '.tpl' else '.html.twig'
        var fileName = 'options' + templateExtension
        if (!shouldBeSkipped(templatePath + fileName)) {
            if (shouldBeMarked(templatePath + fileName)) {
                fileName = 'options.generated' + templateExtension
            }
            fsa.generateFile(templatePath + fileName, if (targets('1.3.x')) optionsTemplateLegacy else optionsTemplate)
        }
    }

    def private optionsTemplateLegacy(Application it) '''
        {* Purpose of this template: Display search options *}
        <input type="hidden" id="«appName.toFirstLower»Active" name="active[«appName»]" value="1" />
        «val appLower = appName.toFirstLower»
        «FOR entity : getAllEntities.filter[hasAbstractStringFieldsEntity]»
            «val nameMulti = entity.nameMultiple.formatForCodeCapital»
            <div>
                <input type="checkbox" id="active_«appLower»«nameMulti»" name="«appLower»SearchTypes[]" value="«entity.name.formatForCode»"{if $active_«entity.name.formatForCode»} checked="checked"{/if} />
                <label for="active_«appLower»«nameMulti»">{gt text='«entity.nameMultiple.formatForDisplayCapital»' domain='module_«appLower.formatForDB»'}</label>
            </div>
        «ENDFOR»
    '''

    def private optionsTemplate(Application it) '''
        {# Purpose of this template: Display search options #}
        <input type="hidden" id="«appName.toFirstLower»Active" name="active[«appName»]" value="1" />
        «val appLower = appName.toFirstLower»
        «FOR entity : getAllEntities.filter[hasAbstractStringFieldsEntity]»
            «val nameMulti = entity.nameMultiple.formatForCodeCapital»
            <div>
                <input type="checkbox" id="active_«appLower»«nameMulti»" name="«appLower»SearchTypes[]" value="«entity.name.formatForCode»"{% if active_«entity.name.formatForCode» %} checked="checked"{% endif %} />
                <label for="active_«appLower»«nameMulti»">{{ __('«entity.nameMultiple.formatForDisplayCapital»', '«appLower.formatForDB»') }}</label>
            </div>
        «ENDFOR»
    '''
}