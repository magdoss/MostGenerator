package org.zikula.modulestudio.generator.cartridges.zclassic.view.additions

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.Entity
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.view.pagecomponents.SimpleFields
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.ModelInheritanceExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.UrlExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class ExternalView {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelExtensions = new ModelExtensions
    extension ModelInheritanceExtensions = new ModelInheritanceExtensions
    extension NamingExtensions = new NamingExtensions
    extension UrlExtensions = new UrlExtensions
    extension Utils = new Utils

    private SimpleFields fieldHelper = new SimpleFields

    def generate(Application it, IMostFileSystemAccess fsa) {
        var fileName = ''
        val templateExtension = '.html.twig'
        for (entity : getAllEntities.filter[hasDisplayAction]) {
            val templatePath = getViewPath + 'External/' + entity.name.formatForCodeCapital + '/'

            fileName = 'display' + templateExtension
            fsa.generateFile(templatePath + fileName, entity.displayTemplate(it))

            fileName = 'info' + templateExtension
            fsa.generateFile(templatePath + fileName, entity.itemInfoTemplate(it))

            fileName = 'find' + templateExtension
            fsa.generateFile(templatePath + fileName, entity.findTemplate(it))

            // content type editing is not ready for Twig yet
            fileName = 'select.tpl'
            fsa.generateFile(templatePath + fileName, entity.selectTemplate(it))
        }
    }

    def private displayTemplate(Entity it, Application app) '''
        {# Purpose of this template: Display one certain «name.formatForDisplay» within an external context #}
        «IF hasImageFieldsEntity»
            {{ pageAddAsset('javascript', asset('magnific-popup/jquery.magnific-popup.min.js')) }}
            {{ pageAddAsset('stylesheet', asset('magnific-popup/magnific-popup.css')) }}
            {{ pageAddAsset('javascript', zasset('@«app.appName»:js/«app.appName».js')) }}
        «ENDIF»
        <div id="«name.formatForCode»{{ «name.formatForCode».getKey() }}" class="«app.appName.toLowerCase»-external-«name.formatForDB»">
        {% if displayMode == 'link' %}
            <p«IF hasDisplayAction» class="«app.appName.toLowerCase»-external-link"«ENDIF»>
            «IF hasDisplayAction»
                <a href="{{ path('«app.appName.formatForDB»_«name.formatForDB»_display'«routeParams(name.formatForCode, true)») }}" title="{{ «name.formatForCode»|«app.appName.formatForDB»_formattedTitle|e('html_attr') }}">
            «ENDIF»
            {{ «name.formatForCode»|«app.appName.formatForDB»_formattedTitle«IF !skipHookSubscribers»|notifyFilters('«app.name.formatForDB».filter_hooks.«nameMultiple.formatForDB».filter')|safeHtml«ENDIF» }}
            «IF hasDisplayAction»
                </a>
            «ENDIF»
            </p>
        {% endif %}
        {% if hasPermission('«app.appName»::', '::', 'ACCESS_EDIT') %}
            {# for normal users without edit permission show only the actual file per default #}
            {% if displayMode == 'embed' %}
                <p class="«app.appName.toLowerCase»-external-title">
                    <strong>{{ «name.formatForCode»|«app.appName.formatForDB»_formattedTitle«IF !skipHookSubscribers»|notifyFilters('«app.name.formatForDB».filter_hooks.«nameMultiple.formatForDB».filter')|safeHtml«ENDIF» }}</strong>
                </p>
            {% endif %}
        {% endif %}

        {% if displayMode == 'link' %}
        {% elseif displayMode == 'embed' %}
            <div class="«app.appName.toLowerCase»-external-snippet">
                «displaySnippet»
            </div>

            {# you can distinguish the context like this: #}
            {# % if source == 'block' %}
                ... detail block
            {% elseif source == 'contentType' %}
                ... detail content type
            {% elseif source == 'scribite' %}
                ...
            {% endif % #}
            «IF hasAbstractStringFieldsEntity || categorisable»

            {# you can enable more details about the item: #}
            {#
                <p class="«app.appName.toLowerCase»-external-description">
                    «displayDescription('', '<br />')»
                    «IF categorisable»
                        {% if featureActivationHelper.isEnabled(constant('«app.vendor.formatForCodeCapital»\\«app.name.formatForCodeCapital»Module\\Helper\\FeatureActivationHelper::CATEGORIES'), '«name.formatForCode»') %}
                            «displayCategories»
                        {% endif %}
                    «ENDIF»
                </p>
            #}
            «ENDIF»
        {% endif %}
        </div>
    '''

    def private displaySnippet(Entity it) '''
        «IF hasImageFieldsEntity»
            «val imageField = getImageFieldsEntity.head»
            «fieldHelper.displayField(imageField, name.formatForCode, 'display')»
        «ELSE»
            &nbsp;
        «ENDIF»
    '''

    def private displayDescription(Entity it, String praefix, String suffix) '''
        «IF hasAbstractStringFieldsEntity»
            «IF hasTextFieldsEntity»
                {% if «name.formatForCode».«getTextFieldsEntity.head.name.formatForCode» is not empty %}«praefix»{{ «name.formatForCode».«getTextFieldsEntity.head.name.formatForCode» }}«suffix»{% endif %}
            «ELSEIF hasStringFieldsEntity»
                {% if «name.formatForCode».«getStringFieldsEntity.head.name.formatForCode» is not empty %}«praefix»{{ «name.formatForCode».«getStringFieldsEntity.head.name.formatForCode» }}«suffix»{% endif %}
            «ENDIF»
        «ENDIF»
    '''

    def private displayCategories(Entity it) '''
        <dl class="category-list">
        {% for propName, catMapping in «name.formatForCode».categories %}
            <dt>{{ propName }}</dt>
            <dd>{{ catMapping.category.display_name[app.request.locale]|default(catMapping.category.name) }}</dd>
        {% endfor %}
        </dl>
    '''

    def private itemInfoTemplate(Entity it, Application app) '''
        {# Purpose of this template: Display item information for previewing from other modules #}
        <dl id="«name.formatForCode»{{ «name.formatForCode».getKey() }}">
        <dt>{{ «name.formatForCode»|«app.appName.formatForDB»_formattedTitle«IF !skipHookSubscribers»|notifyFilters('«app.name.formatForDB».filter_hooks.«nameMultiple.formatForDB».filter')|safeHtml«ENDIF» }}</dt>
        «IF hasImageFieldsEntity»
            <dd>«displaySnippet»</dd>
        «ENDIF»
        «displayDescription('<dd>', '</dd>')»
        «IF categorisable»
            {% if featureActivationHelper.isEnabled(constant('«app.vendor.formatForCodeCapital»\\«app.name.formatForCodeCapital»Module\\Helper\\FeatureActivationHelper::CATEGORIES'), '«name.formatForCode»') %}
                <dd>
                    «displayCategories»
                </dd>
            {% endif %}
        «ENDIF»
        </dl>
    '''

    def private findTemplate(Entity it, Application app) '''
        {# Purpose of this template: Display a popup selector of «nameMultiple.formatForDisplay» for scribite integration #}
        {% set useFinder = true %}
        {% extends '«app.appName»::raw.html.twig' %}
        {% block title __('Search and select «name.formatForDisplay»') %}
        {% block content %}
            <div class="container">
                «findTemplateObjectTypeSwitcher(app)»
                {% form_theme finderForm with [
                    '@«app.appName»/Form/bootstrap_3.html.twig',
                    'ZikulaFormExtensionBundle:Form:form_div_layout.html.twig'
                ] %}
                {{ form_start(finderForm, {attr: {id: '«app.appName.toFirstLower»SelectorForm'}}) }}
                {{ form_errors(finderForm) }}
                <fieldset>
                    <legend>{{ __('Search and select «name.formatForDisplay»') }}</legend>
                    «IF categorisable»
                        {% if featureActivationHelper.isEnabled(constant('«app.vendor.formatForCodeCapital»\\«app.name.formatForCodeCapital»Module\\Helper\\FeatureActivationHelper::CATEGORIES'), '«name.formatForCode»') %}
                            {{ form_row(finderForm.categories) }}
                        {% endif %}
                    «ENDIF»
                    «IF hasImageFieldsEntity»
                        {{ form_row(finderForm.onlyImages) }}
                        <div id="imageFieldRow">
                            {{ form_row(finderForm.imageField) }}
                        </div>
                    «ENDIF»
                    {{ form_row(finderForm.pasteAs) }}
                    <br />
                    «findTemplateObjectId(app)»

                    {{ form_row(finderForm.sort) }}
                    {{ form_row(finderForm.sortdir) }}
                    {{ form_row(finderForm.num) }}
                    «IF hasAbstractStringFieldsEntity»
                        «IF hasImageFieldsEntity»
                            <div id="searchTermRow">
                                {{ form_row(finderForm.q) }}
                            </div>
                        «ELSE»
                            {{ form_row(finderForm.q) }}
                        «ENDIF»
                    «ENDIF»
                    <div>
                        {{ pager({display: 'page', rowcount: pager.numitems, limit: pager.itemsperpage, posvar: 'pos', maxpages: 10, route: '«app.appName.formatForDB»_external_finder'}) }}
                    </div>
                    <div class="form-group">
                        <div class="col-sm-offset-3 col-sm-9">
                            {{ form_widget(finderForm.update) }}
                            {{ form_widget(finderForm.cancel) }}
                        </div>
                    </div>
                </fieldset>
                {{ form_end(finderForm) }}
            </div>

            «findTemplateEditForm(app)»
        {% endblock %}
    '''

    def private findTemplateObjectTypeSwitcher(Entity it, Application app) '''
        «IF app.hasDisplayActions»
            <div class="zikula-bootstrap-tab-container">
                <ul class="nav nav-tabs">
                {% set activatedObjectTypes = getModVar('«app.appName»', 'enabledFinderTypes', []) %}
                «FOR entity : app.getAllEntities.filter[hasDisplayAction]»
                    {% if '«entity.name.formatForCode»' in activatedObjectTypes %}
                        <li{{ objectType == '«entity.name.formatForCode»' ? ' class="active"' : '' }}><a href="{{ path('«app.appName.formatForDB»_external_finder', {objectType: '«entity.name.formatForCode»', editor: editorName}) }}" title="{{ __('Search and select «entity.name.formatForDisplay»') }}">{{ __('«entity.nameMultiple.formatForDisplayCapital»') }}</a></li>
                    {% endif %}
                «ENDFOR»
                </ul>
            </div>
        «ENDIF»
    '''

    def private findTemplateObjectId(Entity it, Application app) '''
        <div class="form-group">
            <label class="col-sm-3 control-label">{{ __('«name.formatForDisplayCapital»') }}:</label>
            <div class="col-sm-9">
                <div id="«app.appName.toLowerCase»ItemContainer">
                    «IF hasImageFieldsEntity»
                        {% if not onlyImages %}
                            <ul>
                        {% endif %}
                    «ELSE»
                        <ul>
                    «ENDIF»
                        {% for «name.formatForCode» in items %}
                            «IF hasImageFieldsEntity»
                            {% if not onlyImages or (attribute(«name.formatForCode», imageField) is not empty and attribute(«name.formatForCode», imageField ~ 'Meta').isImage) %}
                            «ENDIF»
                            «IF hasImageFieldsEntity»
                                {% if not onlyImages %}
                                    <li>
                                {% endif %}
                            «ELSE»
                                <li>
                            «ENDIF»
                                {% set itemId = «name.formatForCode».getKey() %}
                                <a href="#" data-itemid="{{ itemId }}">
                                    «IF hasImageFieldsEntity»
                                        {% if onlyImages %}
                                            {% set thumbOptions = attribute(thumbRuntimeOptions, '«name.formatForCode»' ~ imageField[:1]|upper ~ imageField[1:]) %}
                                            <img src="{{ attribute(«name.formatForCode», imageField).getPathname()|imagine_filter('zkroot', thumbOptions) }}" alt="{{ «name.formatForCode»|«app.appName.formatForDB»_formattedTitle|e('html_attr') }}" width="{{ thumbOptions.thumbnail.size[0] }}" height="{{ thumbOptions.thumbnail.size[1] }}" class="img-rounded" />
                                        {% else %}
                                            {{ «name.formatForCode»|«app.appName.formatForDB»_formattedTitle }}
                                        {% endif %}
                                    «ELSE»
                                        {{ «name.formatForCode»|«app.appName.formatForDB»_formattedTitle }}
                                    «ENDIF»
                                </a>
                                <input type="hidden" id="path{{ itemId }}" value="{{ path('«app.appName.formatForDB»_«name.formatForDB»_display'«routeParams(name.formatForCode, true)») }}" />
                                <input type="hidden" id="url{{ itemId }}" value="{{ url('«app.appName.formatForDB»_«name.formatForDB»_display'«routeParams(name.formatForCode, true)») }}" />
                                <input type="hidden" id="title{{ itemId }}" value="{{ «name.formatForCode»|«app.appName.formatForDB»_formattedTitle|e('html_attr') }}" />
                                <input type="hidden" id="desc{{ itemId }}" value="{% set description %}«displayDescription('', '')»{% endset %}{{ description|striptags|e('html_attr') }}" />
                                «IF hasImageFieldsEntity»
                                    {% if onlyImages %}
                                        <input type="hidden" id="imagePath{{ itemId }}" value="{{ app.request.basePath }}/{{ attribute(«name.formatForCode», imageField).getPathname() }}" />
                                    {% endif %}
                                «ENDIF»
                            «IF hasImageFieldsEntity»
                                {% if not onlyImages %}
                                    </li>
                                {% endif %}
                            «ELSE»
                                </li>
                            «ENDIF»
                            «IF hasImageFieldsEntity»
                            {% endif %}
                            «ENDIF»
                        {% else %}
                            «IF hasImageFieldsEntity»
                                {% if not onlyImages %}<li>{% endif %}{{ __('No «nameMultiple.formatForDisplay» found.') }}{% if not onlyImages %}</li>{% endif %}
                            «ELSE»
                                <li>{{ __('No «nameMultiple.formatForDisplay» found.') }}</li>
                            «ENDIF»
                        {% endfor %}
                    «IF hasImageFieldsEntity»
                        {% if not onlyImages %}
                            </ul>
                        {% endif %}
                    «ELSE»
                        </ul>
                    «ENDIF»
                </div>
            </div>
        </div>
    '''

    def private findTemplateEditForm(Entity it, Application app) '''
        «IF hasEditAction»
            {#
            <div class="«app.appName.toLowerCase»-finderform">
                <fieldset>
                    {{ render(controller('«app.appName»:«name.formatForCodeCapital»:edit')) }}
                </fieldset>
            </div>
            #}
        «ENDIF»
    '''

    def private selectTemplate(Entity it, Application app) '''
        {* Purpose of this template: Display a popup selector for Forms and Content integration *}
        {assign var='baseID' value='«name.formatForCode»'}
        <div id="itemSelectorInfo" class="hidden" data-base-id="{$baseID}" data-selected-id="{$selectedId|default:0}"></div>
        <div class="row">
            <div class="col-sm-8">
                «IF categorisable»

                    {if $properties ne null && is_array($properties)}
                        {gt text='All' assign='lblDefault'}
                        {nocache}
                        {foreach key='propertyName' item='propertyId' from=$properties}
                            <div class="form-group">
                                {assign var='hasMultiSelection' value=$categoryHelper->hasMultipleSelection('«name.formatForCode»', $propertyName)}
                                {gt text='Category' assign='categoryLabel'}
                                {assign var='categorySelectorId' value='catid'}
                                {assign var='categorySelectorName' value='catid'}
                                {assign var='categorySelectorSize' value='1'}
                                {if $hasMultiSelection eq true}
                                    {gt text='Categories' assign='categoryLabel'}
                                    {assign var='categorySelectorName' value='catids'}
                                    {assign var='categorySelectorId' value='catids__'}
                                    {assign var='categorySelectorSize' value='8'}
                                {/if}
                                <label for="{$baseID}_{$categorySelectorId}{$propertyName}" class="col-sm-3 control-label">{$categoryLabel}:</label>
                                <div class="col-sm-9">
                                    {selector_category name="`$baseID`_`$categorySelectorName``$propertyName`" field='id' selectedValue=$catIds.$propertyName|default:null categoryRegistryModule='«app.appName»' categoryRegistryTable="`$objectType`Entity" categoryRegistryProperty=$propertyName defaultText=$lblDefault editLink=false multipleSize=$categorySelectorSize cssClass='form-control'}
                                </div>
                            </div>
                        {/foreach}
                        {/nocache}
                    {/if}
                «ENDIF»
                <div class="form-group">
                    <label for="{$baseID}Id" class="col-sm-3 control-label">{gt text='«name.formatForDisplayCapital»'}:</label>
                    <div class="col-sm-9">
                        <select id="{$baseID}Id" name="id" class="form-control">
                            {foreach item='«name.formatForCode»' from=$items}
                                <option value="{$«name.formatForCode»->getKey()}"{if $selectedId eq $«name.formatForCode»->getKey()} selected="selected"{/if}>{$«name.formatForCode»->get«IF hasDisplayStringFieldsEntity»«getDisplayStringFieldsEntity.head.name.formatForCodeCapital»«ELSE»«getSelfAndParentDataObjects.map[fields].flatten.head.name.formatForCodeCapital»«ENDIF»()}</option>
                            {foreachelse}
                                <option value="0">{gt text='No entries found.'}</option>
                            {/foreach}
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="{$baseID}Sort" class="col-sm-3 control-label">{gt text='Sort by'}:</label>
                    <div class="col-sm-9">
                        <select id="{$baseID}Sort" name="sort" class="form-control">
                            «FOR field : getSortingFields»
                                <option value="«field.name.formatForCode»"{if $sort eq '«field.name.formatForCode»'} selected="selected"{/if}>{gt text='«field.name.formatForDisplayCapital»'}</option>
                            «ENDFOR»
                            «IF standardFields»
                                <option value="createdDate"{if $sort eq 'createdDate'} selected="selected"{/if}>{gt text='Creation date'}</option>
                                <option value="createdBy"{if $sort eq 'createdBy'} selected="selected"{/if}>{gt text='Creator'}</option>
                                <option value="updatedDate"{if $sort eq 'updatedDate'} selected="selected"{/if}>{gt text='Update date'}</option>
                                <option value="updatedBy"{if $sort eq 'updatedBy'} selected="selected"{/if}>{gt text='Updater'}</option>
                            «ENDIF»
                        </select>
                        <select id="{$baseID}SortDir" name="sortdir" class="form-control">
                            <option value="asc"{if $sortdir eq 'asc'} selected="selected"{/if}>{gt text='ascending'}</option>
                            <option value="desc"{if $sortdir eq 'desc'} selected="selected"{/if}>{gt text='descending'}</option>
                        </select>
                    </div>
                </div>
                «IF hasAbstractStringFieldsEntity»
                    <div class="form-group">
                        <label for="{$baseID}SearchTerm" class="col-sm-3 control-label">{gt text='Search for'}:</label>
                        <div class="col-sm-9">
                            <div class="input-group">
                                <input type="text" id="{$baseID}SearchTerm" name="q" class="form-control" />
                                <span class="input-group-btn">
                                    <input type="button" id="«app.appName.toFirstLower»SearchGo" name="gosearch" value="{gt text='Filter'}" class="btn btn-default" />
                                </span>
                            </div>
                        </div>
                    </div>
                «ENDIF»
            </div>
            <div class="col-sm-4">
                <div id="{$baseID}Preview" style="border: 1px dotted #a3a3a3; padding: .2em .5em">
                    <p><strong>{gt text='«name.formatForDisplayCapital» information'}</strong></p>
                    {img id='ajaxIndicator' modname='core' set='ajax' src='indicator_circle.gif' alt='' class='hidden'}
                    <div id="{$baseID}PreviewContainer">&nbsp;</div>
                </div>
            </div>
        </div>
    '''
}
