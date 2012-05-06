package org.zikula.modulestudio.generator.cartridges.zclassic.view.pages

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.AdminController
import de.guite.modulestudio.metamodel.modulestudio.BooleanField
import de.guite.modulestudio.metamodel.modulestudio.Controller
import de.guite.modulestudio.metamodel.modulestudio.DecimalField
import de.guite.modulestudio.metamodel.modulestudio.DerivedField
import de.guite.modulestudio.metamodel.modulestudio.Entity
import de.guite.modulestudio.metamodel.modulestudio.EntityTreeType
import de.guite.modulestudio.metamodel.modulestudio.FloatField
import de.guite.modulestudio.metamodel.modulestudio.IntegerField
import de.guite.modulestudio.metamodel.modulestudio.JoinRelationship
import de.guite.modulestudio.metamodel.modulestudio.NamedObject
import de.guite.modulestudio.metamodel.modulestudio.OneToManyRelationship
import de.guite.modulestudio.metamodel.modulestudio.OneToOneRelationship
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.view.pagecomponents.SimpleFields
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.UrlExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.ViewExtensions
import de.guite.modulestudio.metamodel.modulestudio.UserController

class View {
    @Inject extension ControllerExtensions = new ControllerExtensions()
    @Inject extension FormattingExtensions = new FormattingExtensions()
    @Inject extension ModelExtensions = new ModelExtensions()
    @Inject extension NamingExtensions = new NamingExtensions()
    @Inject extension UrlExtensions = new UrlExtensions()
    @Inject extension Utils = new Utils()
    @Inject extension ViewExtensions = new ViewExtensions()

    SimpleFields fieldHelper = new SimpleFields()

    Integer listType

    /*
      listType:
        0 = div and ul
        1 = div and ol
        2 = div and dl
        3 = div and table
     */
    def generate(Entity it, String appName, Controller controller, Integer listType, IFileSystemAccess fsa) {
        println('Generating ' + controller.formattedName + ' view templates for entity "' + name.formatForDisplay + '"')
        this.listType = listType
        fsa.generateFile(templateFile(controller, name, 'view'), viewView(appName, controller))
    }

    def private viewView(Entity it, String appName, Controller controller) '''
        «val objName = name.formatForCode»
        {* purpose of this template: «nameMultiple.formatForDisplay» view view in «controller.formattedName» area *}
        {include file='«controller.formattedName»/header.tpl'}
        <div class="«appName.toLowerCase»-«name.formatForDB» «appName.toLowerCase»-view">
        {gt text='«name.formatForDisplayCapital» list' assign='templateTitle'}
        {pagesetvar name='title' value=$templateTitle}
        «controller.templateHeader»
        «IF documentation != null && documentation != ''»

            <p class="sectiondesc">«documentation»</p>
        «ENDIF»

        «IF controller.hasActions('edit')»
            {checkpermissionblock component='«appName»::' instance='.*' level="ACCESS_ADD"}
            «IF tree != EntityTreeType::NONE»
                {*
            «ENDIF»
                {gt text='Create «name.formatForDisplay»' assign='createTitle'}
                <a href="{modurl modname='«appName»' type='«controller.formattedName»' func='edit' ot='«objName»'}" title="{$createTitle}" class="z-icon-es-add">
                    {$createTitle}
                </a>
            «IF tree != EntityTreeType::NONE»
                *}
            «ENDIF»
            {/checkpermissionblock}
        «ENDIF»
        {assign var='all' value=0}
        {if isset($showAllEntries) && $showAllEntries eq 1}
            {gt text='Back to paginated view' assign='linkTitle'}
            <a href="{modurl modname='«appName»' type='«controller.formattedName»' func='view' ot='«objName»'}" title="{$linkTitle}" class="z-icon-es-view">
                {$linkTitle}
            </a>
            {assign var='all' value=1}
        {else}
            {gt text='Show all entries' assign='linkTitle'}
            <a href="{modurl modname='«appName»' type='«controller.formattedName»' func='view' ot='«objName»' all=1}" title="{$linkTitle}" class="z-icon-es-view">
                {$linkTitle}
            </a>
        {/if}
        «IF tree != EntityTreeType::NONE»
            {gt text='Switch to hierarchy view' assign='linkTitle'}
            <a href="{modurl modname='«appName»' type='«controller.formattedName»' func='view' ot='«objName»' tpl='tree'}" title="{$linkTitle}" class="z-icon-es-view">
                {$linkTitle}
            </a>
        «ENDIF»

        «viewItemList(appName, controller)»

        {if !isset($showAllEntries) || $showAllEntries ne 1}
            {pager rowcount=$pager.numitems limit=$pager.itemsperpage display='page'}
        {/if}
        «callDisplayHooks(appName, controller)»
        «controller.templateFooter»
        </div>
        {include file='«controller.formattedName»/footer.tpl'}

        «IF hasBooleansWithAjaxToggleEntity»
            <script type="text/javascript" charset="utf-8">
            /* <![CDATA[ */
                document.observe('dom:loaded', function() {
                {{foreach item='«objName»' from=$items}}
                    {{assign var='itemid' value=$«objName».«getFirstPrimaryKey.name.formatForCode»}}
                    «FOR field : getBooleansWithAjaxToggleEntity»
                        «container.application.prefix»InitToggle('«objName»', '«field.name.formatForCode»', '{{$itemid}}');
                    «ENDFOR»
                {{/foreach}}
                });
            /* ]]> */
            </script>
        «ENDIF»
    '''

    def private viewItemList(Entity it, String appName, Controller controller) '''
            «IF listType != 3»
                <«listType.asListTag»>
            «ELSE»
                <table class="z-datatable">
                    <colgroup>
                        «FOR field : getDerivedFields.filter(e|!e.primaryKey)»«field.columnDef»«ENDFOR»
                        «FOR relation : incoming.filter(typeof(OneToManyRelationship)).filter(e|e.bidirectional)»«relation.columnDef(false)»«ENDFOR»
                        «FOR relation : outgoing.filter(typeof(OneToOneRelationship))»«relation.columnDef(true)»«ENDFOR»
                        <col id="citemactions" />
                    </colgroup>
                    <thead>
                    <tr>
                        «FOR field : getDerivedFields.filter(e|!e.primaryKey)»«field.headerLine(controller)»«ENDFOR»
                        «FOR relation : incoming.filter(typeof(OneToManyRelationship)).filter(e|e.bidirectional)»«relation.headerLine(controller, false)»«ENDFOR»
                        «FOR relation : outgoing.filter(typeof(OneToOneRelationship))»«relation.headerLine(controller, true)»«ENDFOR»
                        <th id="hitemactions" scope="col" class="z-right z-order-unsorted">{gt text='Actions'}</th>
                    </tr>
                    </thead>
                    <tbody>
            «ENDIF»

            {foreach item='«name.formatForCode»' from=$items}
                «IF listType < 2»
                    <li><ul>
                «ELSEIF listType == 2»
                    <dt>
                «ELSEIF listType == 3»
                    <tr class="{cycle values='z-odd, z-even'}">
                «ENDIF»
                    «FOR field : getDerivedFields.filter(e|!e.primaryKey)»«field.displayEntry(controller, false)»«ENDFOR»
                    «FOR relation : incoming.filter(typeof(OneToManyRelationship)).filter(e|e.bidirectional)»«relation.displayEntry(controller, false)»«ENDFOR»
                    «FOR relation : outgoing.filter(typeof(OneToOneRelationship))»«relation.displayEntry(controller, true)»«ENDFOR»
                    «itemActions(appName, controller)»
                «IF listType < 2»
                    </ul></li>
                «ELSEIF listType == 2»
                    </dt>
                «ELSEIF listType == 3»
                    </tr>
                «ENDIF»
            {foreachelse}
                «IF listType < 2»
                    <li>
                «ELSEIF listType == 2»
                    <dt>
                «ELSEIF listType == 3»
                    <tr class="z-«controller.tableClass»tableempty">
                      <td class="z-left" colspan="«(fields.size + outgoing.filter(typeof(OneToOneRelationship)).size)»">«/*fields.size -1 (id) +1 (actions)*/»
                «ENDIF»
                {gt text='No «nameMultiple.formatForDisplay» found.'}
                «IF listType < 2»
                    </li>
                «ELSEIF listType == 2»
                    </dt>
                «ELSEIF listType == 3»
                      </td>
                    </tr>
                «ENDIF»
            {/foreach}

            «IF listType != 3»
                <«listType.asListTag»>
            «ELSE»
                    </tbody>
                </table>
            «ENDIF»
    '''

    def private tableClass(Controller it) {
        switch it {
            AdminController: 'admin'
            default: 'data'
        }
    }

    def private callDisplayHooks(Entity it, String appName, Controller controller) {
        switch controller {
            UserController: '''

                {notifydisplayhooks eventname='«appName.formatForDB».ui_hooks.«nameMultiple.formatForDB».display_view' urlobject=$currentUrlObject assign='hooks'}
                {foreach key='providerArea' item='hook' from=$hooks}
                    {$hook}
                {/foreach}
            '''
            default: ''
        }
    }

    def private templateHeader(Controller it) {
        switch it {
            AdminController: '''
                <div class="z-admin-content-pagetitle">
                    {icon type='view' size='small' alt=$templateTitle}
                    <h3>{$templateTitle}</h3>
                </div>
            '''
            default: '''
                <div class="z-frontendcontainer">
                    <h2>{$templateTitle}</h2>
            '''
        }
    }

    def private templateFooter(Controller it) {
        switch it {
            AdminController: ''
            default: '''
                </div>
            '''
        }
    }

    def private columnDef(DerivedField it) '''
        <col id="c«markupIdCode(false)»" />
    '''

    def private columnDef(JoinRelationship it, Boolean useTarget) '''
        <col id="c«markupIdCode(useTarget)»" />
    '''

    def private headerLine(DerivedField it, Controller controller) '''
        <th id="h«markupIdCode(false)»" scope="col" class="z-«alignment»">
            «headerSortingLink(controller, entity, name.formatForCode, name)»
        </th>
    '''

    def private headerLine(JoinRelationship it, Controller controller, Boolean useTarget) '''
        <th id="h«markupIdCode(useTarget)»" scope="col" class="z-left">
            «val mainEntity = (if (useTarget) source else target)»
            «headerSortingLink(controller, mainEntity, getRelationAliasName(useTarget).formatForCode, getRelationAliasName(useTarget).formatForCodeCapital)»
        </th>
    '''

    def private headerSortingLink(Object it, Controller controller, Entity entity, String fieldName, String label) '''
        {sortlink __linktext='«label.formatForDisplayCapital»' sort='«fieldName»' currentsort=$sort sortdir=$sdir all=$all modname='«controller.container.application.appName»' type='«controller.formattedName»' func='view' ot='«entity.name.formatForCode»'}
    '''


    def private displayEntry(Object it, Controller controller, Boolean useTarget) '''
        «IF listType != 3»
            <«listType.asItemTag»>
        «ELSE»
            <td headers="h«markupIdCode(useTarget)»" class="z-«alignment»">
        «ENDIF»
            «displayEntryInner(controller, useTarget)»
        </«listType.asItemTag»>
    '''

    def private dispatch displayEntryInner(Object it, Controller controller, Boolean useTarget) {
    }

    def private dispatch displayEntryInner(DerivedField it, Controller controller, Boolean useTarget) '''
        «IF leading == true»
            {$«entity.name.formatForCode».«name.formatForCode»|notifyfilters:'«entity.container.application.appName.formatForDB».filterhook.«entity.nameMultiple.formatForDB»'}
        «ELSE»
            «fieldHelper.displayField(it, entity.name.formatForCode, 'view')»
        «ENDIF»
    '''

    def private dispatch displayEntryInner(JoinRelationship it, Controller controller, Boolean useTarget) '''
        «val relationAliasName = getRelationAliasName(useTarget).formatForCodeCapital»
        «val mainEntity = (if (!useTarget) target else source)»
        «val linkEntity = (if (useTarget) target else source)»
        «var relObjName = mainEntity.name.formatForCode + '.' + relationAliasName»
        {if isset($«relObjName») && $«relObjName» ne null}
            «IF controller.hasActions('display')»
                «val leadingField = linkEntity.getLeadingField»
                <a href="{modurl modname='«container.application.appName»' type='«controller.formattedName»' «linkEntity.modUrlDisplay(relObjName, true)»}">
                «IF leadingField != null»
                    {$«relObjName».«leadingField.name.formatForCode»«/*|nl2br*/»|default:""}
                «ELSE»
                    {gt text='«linkEntity.name.formatForDisplayCapital»'}
                «ENDIF»
                </a>
                <a id="«linkEntity.name.formatForCode»Item«FOR pkField : mainEntity.getPrimaryKeyFields SEPARATOR '_'»{$«mainEntity.name.formatForCode».«pkField.name.formatForCode»}«ENDFOR»_rel_«FOR pkField : linkEntity.getPrimaryKeyFields SEPARATOR '_'»{$«relObjName».«pkField.name.formatForCode»}«ENDFOR»Display" href="{modurl modname='«container.application.appName»' type='«controller.formattedName»' «linkEntity.modUrlDisplay(relObjName, true)» theme='Printer'«controller.additionalUrlParametersForQuickViewLink»}" title="{gt text='Open quick view window'}" style="display: none">
                    {icon type='view' size='extrasmall' __alt='Quick view'}
                </a>
                <script type="text/javascript" charset="utf-8">
                /* <![CDATA[ */
                    document.observe('dom:loaded', function() {
                        «container.application.prefix»InitInlineWindow($('«linkEntity.name.formatForCode»Item«FOR pkField : mainEntity.getPrimaryKeyFields SEPARATOR '_'»{{$«mainEntity.name.formatForCode».«pkField.name.formatForCode»}}«ENDFOR»_rel_«FOR pkField : linkEntity.getPrimaryKeyFields SEPARATOR '_'»{{$«relObjName».«pkField.name.formatForCode»}}«ENDFOR»Display'), '{{«IF leadingField != null»$«relObjName».«leadingField.name.formatForCode»«ELSE»gt text='«linkEntity.name.formatForDisplayCapital»'«ENDIF»|replace:"'":""}}');
                    });
                /* ]]> */
                </script>
            «ELSE»
                «val leadingField = linkEntity.getLeadingField»
                «IF leadingField != null»
                    {$«relObjName».«leadingField.name.formatForCode»«/*|nl2br*/»|default:""}
                «ELSE»
                    {gt text='«linkEntity.name.formatForDisplayCapital»'}
                «ENDIF»
            «ENDIF»
        {else}
            {gt text='Not set.'}
        {/if}
    '''

    def private dispatch markupIdCode(Object it, Boolean useTarget) {
    }
    def private dispatch markupIdCode(NamedObject it, Boolean useTarget) {
        name.formatForDB
    }
    def private dispatch markupIdCode(DerivedField it, Boolean useTarget) {
        name.formatForDB
    }
    def private dispatch markupIdCode(JoinRelationship it, Boolean useTarget) {
        getRelationAliasName(useTarget).formatForDB
    }

    def private alignment(Object it) {
        switch it {
            BooleanField: 'center'
            IntegerField: 'right'
            DecimalField: 'right'
            FloatField: 'right'
            default: 'left'
        }
    }

    def private itemActions(Entity it, String appName, Controller controller) '''
        «val objName = name.formatForCode»
        «IF listType != 3»
            <«listType.asItemTag»>
        «ELSE»
            <td id="«itemActionContainerId»" headers="hitemactions" class="z-right z-nowrap z-w02">
        «ENDIF»
            {if count($«objName»._actions) gt 0}
                {foreach item='option' from=$«objName»._actions}
                    <a href="{$option.url.type|«appName.formatForDB»ActionUrl:$option.url.func:$option.url.arguments}" title="{$option.linkTitle|safetext}"{if $option.icon eq 'preview'} target="_blank"{/if}>{icon type=$option.icon size='extrasmall' alt=$option.linkText|safetext}</a>
                {/foreach}
                {icon id="«itemActionContainerIdForSmarty»trigger" type='options' size='extrasmall' __alt='Actions' style='display: none'}
            {/if}
            <script type="text/javascript" charset="utf-8">
            /* <![CDATA[ */
                document.observe('dom:loaded', function() {
                    «container.application.prefix»InitItemActions('«name.formatForCode»', 'view', '«itemActionContainerIdForJs»');
                });
            /* ]]> */
            </script>
        </«listType.asItemTag»>
    '''

    def private itemActionContainerId(Entity it) '''
        «val objName = name.formatForCode»
        itemactions«FOR pkField : getPrimaryKeyFields SEPARATOR '_'»{$«objName».«pkField.name.formatForCode»}«ENDFOR»'''

    def private itemActionContainerIdForJs(Entity it) '''
        «val objName = name.formatForCode»
        itemactions«FOR pkField : getPrimaryKeyFields SEPARATOR '_'»{{$«objName».«pkField.name.formatForCode»}}«ENDFOR»'''

    def private itemActionContainerIdForSmarty(Entity it) '''
        «val objName = name.formatForCode»
        itemactions«FOR pkField : getPrimaryKeyFields SEPARATOR '_'»`$«objName».«pkField.name.formatForCode»`«ENDFOR»'''

    def private asListTag (Integer listType) {
        switch listType {
            case 0: 'ul'
            case 1: 'ol'
            case 2: 'dl'
            case 3: 'table'
        }
    }

    def private asItemTag (Integer listType) {
        switch listType {
            case 0: 'li' // ul
            case 1: 'li' // ol
            case 2: 'dd' // dl
            case 3: 'td' // table
        }
    }
}
