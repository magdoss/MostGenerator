package org.zikula.modulestudio.generator.cartridges.zclassic.view

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.DateField
import de.guite.modulestudio.metamodel.DatetimeField
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.ModelJoinExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.WorkflowExtensions

class Layout {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension ModelJoinExtensions = new ModelJoinExtensions
    extension ModelExtensions = new ModelExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils
    extension WorkflowExtensions = new WorkflowExtensions

    IFileSystemAccess fsa

    new(IFileSystemAccess fsa) {
        this.fsa = fsa
    }

    def baseTemplates(Application it) {
        val templatePath = getViewPath
        val templateExtension = '.html.twig'
        var fileName = 'base' + templateExtension
        if (!shouldBeSkipped(templatePath + fileName)) {
            if (shouldBeMarked(templatePath + fileName)) {
                fileName = 'base.generated' + templateExtension
            }
            fsa.generateFile(templatePath + fileName, baseTemplate)
        }
        fileName = 'adminBase' + templateExtension
        if (!shouldBeSkipped(templatePath + fileName)) {
            if (shouldBeMarked(templatePath + fileName)) {
                fileName = 'adminBase.generated' + templateExtension
            }
            fsa.generateFile(templatePath + fileName, adminBaseTemplate)
        }
        fileName = 'Form/bootstrap_3' + templateExtension
        if (!shouldBeSkipped(templatePath + fileName)) {
            if (shouldBeMarked(templatePath + fileName)) {
                fileName = 'Form/bootstrap_3.generated' + templateExtension
            }
            fsa.generateFile(templatePath + fileName, formBaseTemplate)
        }
    }

    def baseTemplate(Application it) '''
        {# purpose of this template: general base layout #}
        {% block header %}
            «/*{{ pageAddAsset('javascript', 'jquery-ui') }}*/»
            {{ pageAddAsset('stylesheet', asset('jquery-ui/themes/base/jquery-ui.min.css')) }}
            {{ pageAddAsset('javascript', asset('bootstrap/js/bootstrap.min.js')) }}
            «IF hasImageFields»
                {{ pageAddAsset('javascript', asset('bootstrap-media-lightbox/bootstrap-media-lightbox.min.js')) }}
                {{ pageAddAsset('stylesheet', asset('bootstrap-media-lightbox/bootstrap-media-lightbox.css')) }}
            «ENDIF»
            «IF hasViewActions || hasDisplayActions || hasEditActions»
                {{ pageAddAsset('stylesheet', asset('bootstrap-jqueryui/bootstrap-jqueryui.min.css')) }}
                {{ pageAddAsset('javascript', asset('bootstrap-jqueryui/bootstrap-jqueryui.min.js')) }}
            «ENDIF»
            {% if app.request.query.get('theme') != 'ZikulaPrinterTheme' %}
                {{ pageAddAsset('javascript', zasset('@«appName»:js/«appName».js')) }}
                «IF hasEditActions»
                    {{ polyfill([«IF hasGeographical»'geolocation', «ENDIF»'forms', 'forms-ext']) }}
                «ENDIF»
            {% endif %}
        {% endblock %}

        {% if app.request.query.get('theme') != 'ZikulaPrinterTheme' %}
            {% block appTitle %}
                {{ moduleHeader('user«/* TODO controller.formattedName */»', '«/* custom title */»', '«/* title link */»', false, true«/* flashes */», false, true«/* image */») }}
            {% endblock %}
        {% endif %}

        {% block titleArea %}
            <h2>{% block title %}{% endblock %}</h2>
        {% endblock %}
        {{ pageSetVar('title', block('pageTitle')|default(block('title'))) }}

        «IF generateModerationPanel && needsApproval»
            {{ block('moderation_panel') }}

        «ENDIF»
        {{ showflashes() }}

        {% block content %}{% endblock %}

        {% block footer %}
            {% if app.request.query.get('theme') != 'ZikulaPrinterTheme' %}
                «IF generatePoweredByBacklinksIntoFooterTemplates»
                    «new FileHelper().msWeblink(it)»
                «ENDIF»
            «IF hasEditActions»
            {% elseif app.request.query.get('func') == 'edit' %}
                {{ pageAddAsset('stylesheet', 'style/core.css') }}
                {{ pageAddAsset('stylesheet', zasset('@«appName»:css/style.css')) }}
                {{ pageAddAsset('stylesheet', zasset('@ZikulaThemeModule:css/form/style.css')) }}
                {{ pageAddAsset('stylesheet', zasset('@ZikulaAndreas08Theme:css/fluid960gs/reset.css')) }}
                {% set pageStyles %}
                <style type="text/css">
                    body {
                        font-size: 70%;
                    }
                </style>
                {% endset %}
                {{ pageAddAsset('header', pageStyles) }}
            «ENDIF»
            {% endif %}
        {% endblock %}
        «IF generateModerationPanel && needsApproval»

            {% block moderation_panel %}
                {% if app.request.query.get('theme') != 'ZikulaPrinterTheme' %}
                    {% set moderationObjects = «appName.formatForDB»_moderationObjects() %}
                    {% if moderationObjects|length > 0 %}
                        {% for modItem in moderationObjects %}
                            <p class="alert alert-info alert-dismissable text-center">
                                <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
                                {% set itemObjectType = modItem.objectType|lower %}
                                <a href="{{ path('«appName.formatForDB»_' ~ itemObjectType ~ '_adminview', { workflowState: modItem.state }) }}" class="bold alert-link">{{ modItem.message }}</a>
                            </p>
                        {% endfor %}
                    {% endif %}
                {% endif %}
            {% endblock %}
        «ENDIF»
    '''

    def adminBaseTemplate(Application it) '''
        {# purpose of this template: admin area base layout #}
        {% extends '«appName»::base.html.twig' %}
        {% block header %}
            {% if app.request.query.get('theme') != 'ZikulaPrinterTheme' %}
                {{ adminHeader() }}
            {% endif %}
            {{ parent() }}
        {% endblock %}
        {% block appTitle %}{# empty on purpose #}{% endblock %}
        {% block titleArea %}
            <h3><span class="fa fa-{% block admin_page_icon %}{% endblock %}"></span>{% block title %}{% endblock %}</h3>
        {% endblock %}
        {% block footer %}
            {% if app.request.query.get('theme') != 'ZikulaPrinterTheme' %}
                {{ adminFooter() }}
            {% endif %}
            {{ parent() }}
        {% endblock %}
    '''

    def formBaseTemplate(Application it) '''
        {# purpose of this template: apply some general form extensions #}
        {% extends 'ZikulaFormExtensionBundle:Form:bootstrap_3_zikula_admin_layout.html.twig' %}
        «IF !getAllEntities.filter[e|!e.fields.filter(DateField).empty].empty»

            {%- block date_widget -%}
                {{- parent() -}}
                {%- if not required -%}
                    <span class="help-block"><a id="{{ id }}ResetVal" href="javascript:void(0);" class="hidden">{{ __('Reset to empty value') }}</a></span>
                {%- endif -%}
            {%- endblock -%}
        «ENDIF»
        «IF !getAllEntities.filter[e|!e.fields.filter(DatetimeField).empty].empty»

            {%- block datetime_widget -%}
                {{- parent() -}}
                {%- if not required -%}
                    <span class="help-block"><a id="reset{{ id }}ResetVal" href="javascript:void(0);" class="hidden">{{ __('Reset to empty value') }}</a></span>
                {%- endif -%}
            {%- endblock -%}
        «ENDIF»
        «IF hasColourFields»

            {%- block «appName.formatForDB»_field_colour_widget -%}
                {%- set type = type|default('color') -%}
                {{ block('form_widget_simple') }}
            {%- endblock -%}
        «ENDIF»
        «IF hasUploads»

            {% block «appName.formatForDB»_field_upload_label %}{% endblock %}
            {% block «appName.formatForDB»_field_upload_row %}
                {% spaceless %}
                {{ form_row(attribute(form, fieldName)) }}
                <div class="col-sm-9 col-sm-offset-3">
                    {% if not required %}
                        <span class="help-block"><a id="{{ id }}_{{ fieldName }}ResetVal" href="javascript:void(0);" class="hidden">{{ __('Reset to empty value') }}</a></span>
                    {% endif %}
                    <span class="help-block">{{ __('Allowed file extensions') }}: <span id="{{ id }}_{{ fieldName }}FileExtensions">{{ allowed_extensions|default('') }}</span></span>
                    {% if allowed_size|default is not null and allowed_size > 0 %}
                        <span class="help-block">{{ __('Allowed file size') }}: {{ allowed_size|«appName.formatForDB»_fileSize('', false, false) }}</span>
                    {% endif %}
                    {% if file_path|default %}
                        <span class="help-block">
                            {{ __('Current file') }}:
                            <a href="{{ file_url }}" title="{{ __('Open file') }}"{% if file_meta.isImage %} class="lightbox"{% endif %}>
                            {% if file_meta.isImage %}
                                <img src="{{ file_path|imagine_filter('zkroot', thumbRuntimeOptions) }}" alt="{{ formattedEntityTitle|e('html_attr') }}" width="{{ thumbRuntimeOptions.thumbnail.size[0] }}" height="{{ thumbRuntimeOptions.thumbnail.size[1] }}" class="img-thumbnail" />
                            {% else %}
                                {{ __('Download') }} ({{ file_meta.size|«appName.formatForDB»_fileSize(file_path, false, false) }})
                            {% endif %}
                            </a>
                        </span>
                        {% if not required %}
                            {{ form_row(attribute(form, fieldName ~ 'DeleteFile')) }}
                        {% endif %}
                    {% endif %}
                </div>
                {% endspaceless %}
            {% endblock %}
        «ENDIF»
        «IF hasUserFields»

            {% block «appName.formatForDB»_field_user_widget %}
                <div id="{{ id }}LiveSearch" class="«appName.toLowerCase»-livesearch-user «appName.toLowerCase»-autocomplete-user hidden">
                    <i class="fa fa-search" title="{{ __('Search user') }}"></i>
                    <noscript><p>{{ __('This function requires JavaScript activated!') }}</p></noscript>
                    <input type="hidden" {{ block('widget_attributes') }} value="{{ value }}" />
                    <input type="text" id="{{ id }}Selector" name="{{ id }}Selector" autocomplete="off" value="{% if value > 0 %}{{ «appName.formatForDB»_userVar('uname', value) }}{% endif %}" title="{{ __('Enter a part of the user name to search') }}" class="user-selector typeahead" />
                    <i class="fa fa-refresh fa-spin hidden" id="{{ id }}Indicator"></i>
                    <span id="{{ id }}NoResultsHint" class="hidden">{{ __('No results found!') }}</span>
                </div>
                {% if value and not inlineUsage %}
                    <span class="help-block avatar">
                        {{ «appName.formatForDB»_userAvatar(uid=value, rating='g') }}
                    </span>
                    {% if hasPermission('ZikulaUsersModule::', '::', 'ACCESS_ADMIN') %}
                        <span class="help-block"><a href="{{ path('zikulausersmodule_admin_modify', { 'userid': value }) }}" title="{{ __('Switch to users administration') }}">{{ __('Manage user') }}</a></span>
                    {% endif %}
                {% endif %}
            {% endblock %}
        «ENDIF»
        «IF needsAutoCompletion»

            {% block «appName.formatForDB»_field_autocompletionrelation_widget %}
                {% set entityNameTranslated = '' %}
                {% set withImage = false %}
                «FOR entity : entities»
                    {% «IF entity != entities.head»else«ENDIF»if objectType == '«entity.name.formatForCode»' %}
                        {% set entityNameTranslated = __('«entity.name.formatForDisplay»') %}
                        «IF entity.hasImageFieldsEntity»
                            {% set withImage = true %}
                        «ENDIF»
                «ENDFOR»
                {% endif %}
                {% set idPrefix = uniqueNameForJs %}
                {% set addLinkText = multiple ? __f('Add %name%', { '%name%': entityNameTranslated }) : __f('Select %name%', { '%entityName%': entityNameTranslated }) %}
                {% set createLink = createUrl != '' ? '<a id="' ~ uniqueNameForJs ~ 'SelectorDoNew" href="' ~ createUrl ~ '" title="' ~ __f('Create new %name%', { '%name%': entityNameTranslated }) ~ '" class="btn btn-default «appName.toLowerCase»-inline-button">' ~ __('Create') ~ '</a>' : '' %}

                <div class="«appName.toLowerCase»-relation-rightside">'
                    <a id="{{ uniqueNameForJs }}AddLink" href="javascript:void(0);" class="hidden">{{ addLinkText }}</a>
                    <div id="{{ idPrefix }}AddFields" class="«appName.toLowerCase»-autocomplete{{ withImage ? '-with-image' : '' }}">
                        <label for="{{ idPrefix }}Selector">{{ __f('Find %name%', { '%name%': entityNameTranslated }) }}</label>
                        <br />
                        <i class="fa fa-search" title="{{ __f('Search %name%', { '%name%': entityNameTranslated })|e('html_attr') }}"></i>
                        <input type="hidden" name="{{ idPrefix }}Scope" id="{{ idPrefix }}Scope" value="{{ multiple ? '0' : '1' }}" />
                        <input type="text" id="{{ idPrefix }}Selector" name="{{ idPrefix }}Selector" value="{# value #}" autocomplete="off" {#{ block('widget_attributes') }#} />
                        <i class="fa fa-refresh fa-spin hidden" id="{{ idPrefix }}Indicator"></i>
                        <span id="{{ idPrefix }}NoResultsHint" class="hidden">{{ __('No results found!') }}</span>
                        <input type="button" id="{{ idPrefix }}SelectorDoCancel" name="{{ idPrefix }}SelectorDoCancel" value="{{ __('Cancel') }}" class="btn btn-default «appName.toLowerCase»-inline-button" />
                        {{ createLink }}
                        <noscript><p>{{ __('This function requires JavaScript activated!') }}</p></noscript>
                    </div>
                </div>
            {% endblock %}
        «ENDIF»
    '''

    def pdfHeaderFile(Application it) {
        val templateExtension = '.html.twig'
        var fileName = 'includePdfHeader' + templateExtension
        if (!shouldBeSkipped(getViewPath + fileName)) {
            if (shouldBeMarked(getViewPath + fileName)) {
                fileName = 'includePdfHeader.generated' + templateExtension
            }
            fsa.generateFile(getViewPath + fileName, pdfHeaderImpl)
        }
    }

    def private pdfHeaderImpl(Application it) '''
        <!DOCTYPE html>
        <html xml:lang="{{ app.request.locale }}" lang="{{ app.request.locale }}" dir="{{ localeApi.language_direction }}">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <title>{{ pageGetVar('title') }}</title>
        <style>
            @page {
                margin: 0 2cm 1cm 1cm;
            }

            img {
                border-width: 0;
                vertical-align: middle;
            }
        </style>
        </head>
        <body>
    '''
}
