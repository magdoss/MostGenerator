package org.zikula.modulestudio.generator.extensions

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.Application
import de.guite.modulestudio.metamodel.modulestudio.Controller
import de.guite.modulestudio.metamodel.modulestudio.Entity
import de.guite.modulestudio.metamodel.modulestudio.JoinRelationship
import org.eclipse.xtext.generator.IFileSystemAccess

/**
 * Extension methods for naming classes and building file pathes.
 */
class NamingExtensions {

    /**
     * Extensions related to the controller layer.
     */
    @Inject extension ControllerExtensions = new ControllerExtensions

    /**
     * Extensions used for formatting element names.
     */
    @Inject extension FormattingExtensions = new FormattingExtensions

    /**
     * Helper methods for generator settings.
     */
    @Inject extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions

    /**
     * Additional utility methods.
     */
    @Inject extension Utils = new Utils

    /**
     * Concatenates two strings being used for a template path.
     */
    def prepTemplatePart(String origin, String addition) {
        origin + addition.toLowerCase
    }

    /**
     * Returns the common suffix for template file names.
     */
    def templateSuffix() {
        '.tpl'
    }

    /**
     * Returns the base path for a certain template file.
     */
    def templateFileBase(Controller it, String entityName, String actionName) {
        if (container.application.targets('1.3.5'))
            container.application.getViewPath + formattedName + '/' + entityName.formatForCode + '/' + actionName
        else
            container.application.getViewPath + formattedName.toFirstUpper + '/' + entityName.formatForCodeCapital + '/' + actionName
    }

    /**
     * Returns the full template file path for given controller action and entity.
     */
    def templateFile(Controller it, String entityName, String actionName) {
        templateFileBase(entityName, actionName) + templateSuffix
    }

    /**
     * Returns the full template file path for given controller action and entity,
     * using a custom template extension (like xml instead of tpl).
     */
    def templateFileWithExtension(Controller it, String entityName, String actionName, String templateExtension) {
        templateFileBase(entityName, actionName) + '.' + templateExtension + templateSuffix
    }

    /**
     * Returns the full template file path for given controller edit action and entity.
     */
    def editTemplateFile(Controller it, String entityName, String actionName) {
        templateFile(entityName, actionName)
    }
    

    /**
     * Returns the full file path for a view plugin file.
     */
    def viewPluginFilePath(Application it, String pluginType, String pluginName) {
        getViewPath + 'plugins/' + pluginType + '.' + appName.formatForDB + pluginName + '.php'
    }


    /**
     * Returns the alias name for one side of a given relationship.
     */
    def getRelationAliasName(JoinRelationship it, Boolean useTarget) {
        var String result
        if (useTarget && targetAlias !== null && targetAlias != '') {
            result = targetAlias
        } else if (!useTarget && sourceAlias !== null && sourceAlias != '') {
            result = sourceAlias
        } else {
            result = (if (useTarget) target else source).entityClassName('', false)
        }

        result.formatForCode
    }

    /**
     * Returns the class name for a certain entity class.
     */
    def entityClassName(Entity it, String suffix, Boolean isBase) {
        val app = container.application
        if (app.targets('1.3.5'))
            app.appName + '_Entity_' + (if (isBase) 'Base_' else '') + name.formatForCodeCapital + suffix.formatForCodeCapital
        else
            app.vendor.formatForCodeCapital + '\\' + app.name.formatForCodeCapital + 'Module\\Entity\\' + (if (isBase) 'Base\\' else '') + name.formatForCodeCapital + suffix.formatForCodeCapital + 'Entity'
    }

    /**
     * Checks whether a certain file path is contained in the blacklist for files to be skipped during generation.
     */
    def shouldBeSkipped(Application it, String filePath) {
        getListOfFilesToBeSkipped.contains(filePath.replace(getAppSourcePath, ''))
    }

    /**
     * Generates a base class and an inheriting concrete class with
     * the corresponding content.
     *
     * @param it              The {@link Application} instance.
     * @param fsa             Given file system access.
     * @param concretePath    Path to concrete class file.
     * @param baseContent     Content for base class file.
     * @param concreteContent Content for concrete class file.
     */
    def generateClassPair(Application it, IFileSystemAccess fsa, String concretePath, CharSequence baseContent, CharSequence concreteContent) {
        var basePathParts = concretePath.split('/') //$NON-NLS-1$
        var basePathPartsChangeable = newArrayList(basePathParts)
        basePathPartsChangeable.add(basePathPartsChangeable.size-1, 'Base') //$NON-NLS-1$
        val basePath = basePathPartsChangeable.join('/') //$NON-NLS-1$

        if (!shouldBeSkipped(basePath)) {
            fsa.generateFile(basePath, baseContent)
        }
        if (!generateOnlyBaseClasses && !shouldBeSkipped(concretePath)) {
            fsa.generateFile(concretePath, concreteContent)
        }
    }

    /**
     * Returns the base path for the generated application.
     */
    def getAppSourcePath(Application it) {
        if (targets('1.3.5'))
            'src/modules/' + appName + '/'
        else
            vendor.formatForCodeCapital + '/' + name.formatForCodeCapital + 'Module/'
    }

    /**
     * Returns the base path for the source code of the generated application.
     */
    def getAppSourceLibPath(Application it) {
        if (targets('1.3.5'))
            getAppSourcePath + 'lib/' + appName + '/'
        else
            getAppSourcePath
    }

    /**
     * Returns the base path for any documentation.
     */
    def getAppDocPath(Application it) {
        if (targets('1.3.5'))
            getAppSourcePath + 'docs/'
        else
            getResourcesPath + 'docs/'
    }

    /**
     * Returns the base path for the locale artifacts.
     */
    def getAppLocalePath(Application it) {
        if (targets('1.3.5'))
            getAppSourcePath + 'locale/'
        else
            getResourcesPath + 'locale/'
    }

    /**
     * Returns the base path for any resources.
     */
    def getResourcesPath(Application it) {
        getAppSourcePath + 'Resources/'
    }

    /**
     * Returns the base path for any assets.
     */
    def getAssetPath(Application it) {
        getResourcesPath + 'public/'
    }

    /**
     * Returns the base path for all view templates.
     */
    def getViewPath(Application it) {
        if (targets('1.3.5'))
            getAppSourcePath + 'templates/'
        else
            getResourcesPath + 'views/'
    }

    /**
     * Returns the base path for image files.
     */
    def getAppImagePath(Application it) {
        if (targets('1.3.5'))
            getAppSourcePath + 'images/'
        else
            getAssetPath + 'images/'
    }

    /**
     * Returns the base path for css files.
     */
    def getAppCssPath(Application it) {
        if (targets('1.3.5'))
            getAppSourcePath + 'style/'
        else
            getAssetPath + 'css/'
    }

    /**
     * Returns the base path for js files.
     */
    def getAppJsPath(Application it) {
        if (targets('1.3.5'))
            getAppSourcePath + 'javascript/'
        else
            getAssetPath + 'js/'
    }

    /**
     * Returns the base path for uploaded files of the generated application.
     */
    def getAppUploadPath(Application it) {
        if (targets('1.3.5'))
            'src/userdata/' + appName + '/'
        else
            getResourcesPath + 'userdata/' + appName + '/'
    }

    /**
     * Returns the base path for the test source code of the generated application.
     */
    def getAppTestsPath(Application it) {
        if (targets('1.3.5'))
            'tests/'
        else
            getAppSourcePath + 'Tests/'
    }
}
