package org.zikula.modulestudio.generator.cartridges.zclassic.controller.action

import de.guite.modulestudio.metamodel.Action
import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.CustomAction
import de.guite.modulestudio.metamodel.DeleteAction
import de.guite.modulestudio.metamodel.DisplayAction
import de.guite.modulestudio.metamodel.EditAction
import de.guite.modulestudio.metamodel.Entity
import de.guite.modulestudio.metamodel.MainAction
import de.guite.modulestudio.metamodel.ViewAction
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.ViewExtensions

class Annotations {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension ModelExtensions = new ModelExtensions
    extension Utils = new Utils
    extension ViewExtensions = new ViewExtensions

    Application app

    new(Application app) {
        this.app = app
    }

    def generate(Action it, Entity entity, Boolean isBase, Boolean isAdmin) '''
        «IF !isBase»
            «actionRoute(entity, isAdmin)»
        «ELSE»
            «IF null !== entity»
                «IF isAdmin»
                    «' '»* @Theme("admin")
                «ENDIF»
                «IF it instanceof DisplayAction || it instanceof DeleteAction»
                    «paramConverter(entity)»
                «ENDIF»
                «IF it instanceof MainAction»
                    «' '»* @Cache(expires="+7 days", public=true)
                «ELSEIF it instanceof ViewAction»
                    «' '»* @Cache(expires="+2 hours", public=false)
                «ELSEIF !(it instanceof CustomAction)»
                    «IF entity.standardFields»
                        «' '»* @Cache(lastModified="«entity.name.formatForCode».getUpdatedDate()", ETag="'«entity.name.formatForCodeCapital»' ~ «entity.getPrimaryKeyFields.map[entity.name.formatForCode + '.get' + name.formatForCode + '()'].join(' ~ ')» ~ «entity.name.formatForCode».getUpdatedDate().format('U')")
                    «ELSE»
                        «IF it instanceof EditAction»
                            «' '»* @Cache(expires="+30 minutes", public=false)
                        «ELSE»
                            «' '»* @Cache(expires="+12 hours", public=false)
                        «ENDIF»
                    «ENDIF»
                «ENDIF»
            «ENDIF»
        «ENDIF»
    '''

    def private dispatch actionRoute(Action it, Entity entity, Boolean isAdmin) '''
    '''

    def private dispatch actionRoute(MainAction it, Entity entity, Boolean isAdmin) '''
         «' '»*
         «' '»* @Route("/«IF null !== entity»«IF isAdmin»admin/«ENDIF»«entity.nameMultiple.formatForCode»«ELSE»«controller.formattedName»«ENDIF»",
         «' '»*        methods = {"GET"}
         «' '»* )
    '''

    def private dispatch actionRoute(ViewAction it, Entity entity, Boolean isAdmin) '''
         «' '»*
         «' '»* @Route("/«IF isAdmin»admin/«ENDIF»«entity.nameMultiple.formatForCode»/view/{sort}/{sortdir}/{pos}/{num}.{_format}",
         «' '»*        requirements = {"sortdir" = "asc|desc|ASC|DESC", "pos" = "\d+", "num" = "\d+", "_format" = "html«IF app.getListOfViewFormats.size > 0»|«FOR format : app.getListOfViewFormats SEPARATOR '|'»«format»«ENDFOR»«ENDIF»"},
         «' '»*        defaults = {"sort" = "", "sortdir" = "asc", "pos" = 1, "num" = 0, "_format" = "html"},
         «' '»*        methods = {"GET"}
         «' '»* )
    '''

    def private actionRouteForSingleEntity(Entity it, Action action, Boolean isAdmin) '''
         «' '»*
         «' '»* @Route("/«IF isAdmin»admin/«ENDIF»«name.formatForCode»/«IF !(action instanceof DisplayAction)»«action.name.formatForCode»/«ENDIF»«actionRouteParamsForSingleEntity(action)».{_format}",
         «' '»*        requirements = {«actionRouteRequirementsForSingleEntity(action)», "_format" = "html«IF action instanceof DisplayAction && app.getListOfDisplayFormats.size > 0»|«FOR format : app.getListOfDisplayFormats SEPARATOR '|'»«format»«ENDFOR»«ENDIF»"},
         «' '»*        defaults = {«IF action instanceof EditAction»«actionRouteDefaultsForSingleEntity(action)», «ENDIF»"_format" = "html"},
         «' '»*        methods = {"GET"«IF action instanceof EditAction || action instanceof DeleteAction», "POST"«ENDIF»}
         «' '»* )
    '''

    def private actionRouteParamsForSingleEntity(Entity it, Action action) {
        var output = ''
        if (hasSluggableFields && !(action instanceof EditAction)) {
            output = '{slug}'
            if (slugUnique) {
                return output
            }
            output = output + '.'
        }
        output = output + getPrimaryKeyFields.map['{' + name.formatForCode + '}'].join('_')

        output
    }

    def private actionRouteRequirementsForSingleEntity(Entity it, Action action) {
        var output = ''
        if (hasSluggableFields && !(action instanceof EditAction)) {
            output = '''"slug" = "[^/.]+"'''
            if (slugUnique) {
                return output
            }
        }
        output = output + getPrimaryKeyFields.map['''"«name.formatForCode»" = "\d+"'''].join(', ')

        output
    }

    def private actionRouteDefaultsForSingleEntity(Entity it, Action action) {
        var output = ''
        if (hasSluggableFields && action instanceof DisplayAction) {
            output = '''"slug" = ""'''
            if (slugUnique) {
                return output
            }
        }
        output = output + getPrimaryKeyFields.map['''"«name.formatForCode»" = "0"'''].join(', ')

        output
    }

    def private dispatch actionRoute(DisplayAction it, Entity entity, Boolean isAdmin) '''
        «actionRouteForSingleEntity(entity, it, isAdmin)»
    '''

    def private dispatch actionRoute(EditAction it, Entity entity, Boolean isAdmin) '''
        «actionRouteForSingleEntity(entity, it, isAdmin)»
    '''

    def private dispatch actionRoute(DeleteAction it, Entity entity, Boolean isAdmin) '''
        «actionRouteForSingleEntity(entity, it, isAdmin)»
    '''

    def private dispatch actionRoute(CustomAction it, Entity entity, Boolean isAdmin) '''
         «' '»*
         «' '»* @Route("/«IF null !== entity»«IF isAdmin»admin/«ENDIF»«entity.nameMultiple.formatForCode»«ELSE»«controller.formattedName»«ENDIF»/«name.formatForCode»",
         «' '»*        methods = {"GET", "POST"}
         «' '»* )
    '''

    // currently called for DisplayAction and DeleteAction
    def private paramConverter(Entity it) '''
         «' '»* @ParamConverter("«name.formatForCode»", class="«app.appName»:«name.formatForCodeCapital»Entity", options={«paramConverterOptions»})
    '''

    def private paramConverterOptions(Entity it) {
        var output = ''
        if (hasSluggableFields && slugUnique) {
            output = '"id" = "slug", "repository_method" = "selectBySlug"'
            // since we use the id property selectBySlug receives the slug value directly instead ['slug' => 'my-title']
            return output
        }
        val needsMapping = hasSluggableFields || hasCompositeKeys
        if (!needsMapping) {
            output = '"id" = "' + getFirstPrimaryKey.name.formatForCode + '", "repository_method" = "selectById"'
            // since we use the id property selectById receives the slug value directly instead ['id' => 123]
            return output
        }

        // we have no single primary key or unique slug so we need to define a mapping hash option
        if (hasSluggableFields) {
            output = output + '"slug": "slug"'
        }

        output = output + getPrimaryKeyFields.map['"' + name.formatForCode + '": "' + name.formatForCode + '"'].join(', ')
        output = output + ', "repository_method" = "selectByIdList"'
        // selectByIdList receives an array like ['fooid' => 123, 'otherfield' => 456]

        // add mapping hash
        output = '"mapping": {' + output + '}'

        output
    }
}
