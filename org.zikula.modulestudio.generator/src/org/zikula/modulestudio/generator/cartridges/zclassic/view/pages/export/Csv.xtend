package org.zikula.modulestudio.generator.cartridges.zclassic.view.pages.export

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.BooleanField
import de.guite.modulestudio.metamodel.modulestudio.Controller
import de.guite.modulestudio.metamodel.modulestudio.DerivedField
import de.guite.modulestudio.metamodel.modulestudio.Entity
import de.guite.modulestudio.metamodel.modulestudio.JoinRelationship
import de.guite.modulestudio.metamodel.modulestudio.ManyToManyRelationship
import de.guite.modulestudio.metamodel.modulestudio.OneToManyRelationship
import de.guite.modulestudio.metamodel.modulestudio.OneToOneRelationship
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.view.pagecomponents.SimpleFields
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions

class Csv {
    @Inject extension ControllerExtensions = new ControllerExtensions
    @Inject extension FormattingExtensions = new FormattingExtensions
    @Inject extension ModelExtensions = new ModelExtensions
    @Inject extension NamingExtensions = new NamingExtensions

    SimpleFields fieldHelper = new SimpleFields

    def generate(Entity it, String appName, Controller controller, IFileSystemAccess fsa) {
        val templateFilePath = templateFileWithExtension(controller, name, 'view', 'csv')
        if (!container.application.shouldBeSkipped(templateFilePath)) {
            println('Generating ' + controller.formattedName + ' csv view templates for entity "' + name.formatForDisplay + '"')
            fsa.generateFile(templateFilePath, csvView(appName, controller))
        }
    }

    def private csvView(Entity it, String appName, Controller controller) '''
        {* purpose of this template: «nameMultiple.formatForDisplay» view csv view in «controller.formattedName» area *}
        {«appName.formatForDB»TemplateHeaders contentType='text/comma-separated-values; charset=iso-8859-15' asAttachment=true filename='«nameMultiple.formatForCodeCapital».csv'}
        {strip}«FOR field : getDisplayFields.filter[name != 'workflowState'] SEPARATOR ';'»«field.headerLine»«ENDFOR»«IF geographical»«FOR geoFieldName : newArrayList('latitude', 'longitude')»;"{gt text='«geoFieldName.formatForDisplayCapital»'}"«ENDFOR»«ENDIF»«IF softDeleteable»;"{gt text='Deleted at'}"«ENDIF»;"{gt text='Workflow state'}"
        «FOR relation : incoming.filter(OneToManyRelationship).filter[bidirectional]»«relation.headerLineRelation(false)»«ENDFOR»
        «FOR relation : outgoing.filter(OneToOneRelationship)»«relation.headerLineRelation(true)»«ENDFOR»
        «FOR relation : incoming.filter(ManyToManyRelationship).filter[bidirectional]»«relation.headerLineRelation(false)»«ENDFOR»
        «FOR relation : outgoing.filter(OneToManyRelationship)»«relation.headerLineRelation(true)»«ENDFOR»
        «FOR relation : outgoing.filter(ManyToManyRelationship)»«relation.headerLineRelation(true)»«ENDFOR»{/strip}
        «val objName = name.formatForCode»
        {foreach item='«objName»' from=$items}
        {strip}
            «FOR field : getDisplayFields.filter[e|e.name != 'workflowState'] SEPARATOR ';'»«field.displayEntry(controller)»«ENDFOR»«IF geographical»«FOR geoFieldName : newArrayList('latitude', 'longitude')»;"{$«name.formatForCode».«geoFieldName»|«appName.formatForDB»FormatGeoData}"«ENDFOR»«ENDIF»«IF softDeleteable»;"{$item.deletedAt|dateformat:'datebrief'}"«ENDIF»;"{$item.workflowState|«appName.formatForDB»ObjectState:false|lower}"
            «FOR relation : incoming.filter(OneToManyRelationship).filter[bidirectional]»«relation.displayRelatedEntry(controller, false)»«ENDFOR»
            «FOR relation : outgoing.filter(OneToOneRelationship)»«relation.displayRelatedEntry(controller, true)»«ENDFOR»
            «FOR relation : incoming.filter(ManyToManyRelationship).filter[bidirectional]»«relation.displayRelatedEntries(controller, false)»«ENDFOR»
            «FOR relation : outgoing.filter(OneToManyRelationship)»«relation.displayRelatedEntries(controller, true)»«ENDFOR»
            «FOR relation : outgoing.filter(ManyToManyRelationship)»«relation.displayRelatedEntries(controller, true)»«ENDFOR»
        {/strip}
        {/foreach}
    '''

    def private headerLine(DerivedField it) '''
        "{gt text='«name.formatForDisplayCapital»'}"'''

    def private headerLineRelation(JoinRelationship it, Boolean useTarget) ''';"{gt text='«getRelationAliasName(useTarget).formatForDisplayCapital»'}"'''

    def private dispatch displayEntry(DerivedField it, Controller controller) '''
        "«fieldHelper.displayField(it, entity.name.formatForCode, 'viewcsv')»"'''

    def private dispatch displayEntry(BooleanField it, Controller controller) '''
        "{if !$«entity.name.formatForCode».«name.formatForCode»}0{else}1{/if}"'''

    def private displayRelatedEntry(JoinRelationship it, Controller controller, Boolean useTarget) '''
        «val relationAliasName = getRelationAliasName(useTarget).formatForCodeCapital»
        «val mainEntity = (if (!useTarget) target else source)»
        «val relObjName = mainEntity.name.formatForCode + '.' + relationAliasName»
        ;"{if isset($«relObjName») && $«relObjName» ne null}{$«relObjName»->getTitleFromDisplayPattern()|default:''}{/if}"'''

    def private displayRelatedEntries(JoinRelationship it, Controller controller, Boolean useTarget) '''
        «val relationAliasName = getRelationAliasName(useTarget).formatForCodeCapital»
        «val mainEntity = (if (!useTarget) target else source)»
        «val relObjName = mainEntity.name.formatForCode + '.' + relationAliasName»
        ;"
            {if isset($«relObjName») && $«relObjName» ne null}
                {foreach name='relationLoop' item='relatedItem' from=$«relObjName»}
                {$relatedItem->getTitleFromDisplayPattern()|default:''}{if !$smarty.foreach.relationLoop.last}, {/if}
                {/foreach}
            {/if}
        "'''
}
