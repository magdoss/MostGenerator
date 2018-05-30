package org.zikula.modulestudio.generator.extensions

import de.guite.modulestudio.metamodel.Application
import java.util.Date
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess
import org.zikula.modulestudio.generator.application.MostInMemoryFileSystemAccess

/**
 * Miscellaneous utility methods.
 */
class Utils {

    /**
     * Extensions used for formatting element names.
     */
    extension FormattingExtensions = new FormattingExtensions

    /**
     * Returns a "generated by" message.
     */
    def generatedBy(Application it, Boolean includeTimestamp, Boolean includeVersion)
        '''Generated by ModuleStudio «IF includeVersion»«msVersion» «ENDIF»(«msUrl»)«IF includeTimestamp» at «timestamp»«ENDIF».'''

    /**
     * Returns the version number of ModuleStudio.
     *
     * @return String The version number
     */
    def msVersion() {
        '1.3.1'
    }

    /**
     * Returns the website URL of ModuleStudio.
     *
     * @return String The website URL
     */
    def msUrl() {
        'https://modulestudio.de'
    }

    /**
     * Returns the application's description.
     *
     * @return String The description
     */
    def appDescription(Application it) {
        if (null !== documentation && !documentation.empty) {
            return documentation.replace('"', "'")
        }
        '''«appName» generated by ModuleStudio «msVersion».'''
    }

    /**
     * Creates a placeholder file in a given file path.
     *
     * @param it The file system access
     * @param path The file path
     */
    def createPlaceholder(IMostFileSystemAccess it, String path) {
        var fileName = 'README'
        val fileContent = '''This file is a placeholder.
        '''
        generateFile(path + fileName, fileContent)
    }

    /**
     * Returns a combined title consisting of vendor and name.
     *
     * @param it The {@link Application} instance
     *
     * @return String The formatted name
     */
    def String vendorAndName(Application it) {
        vendor.formatForCode + name.formatForCodeCapital
    }

    /**
     * Returns the formatted name of the application.
     *
     * @param it The {@link Application} instance
     *
     * @return String The formatted name
     */
    def String appName(Application it) {
        vendor.formatForCodeCapital + name.formatForCodeCapital + 'Module'
    }

    /**
     * Returns the base namespace of the application.
     *
     * @param it The {@link Application} instance
     *
     * @return String The formatted namespace
     */
    def appNamespace(Application it) {
        vendor.formatForCodeCapital + '\\' + name.formatForCodeCapital + 'Module'
    }

    /**
     * Returns prefix for service names for this application.
     *
     * @param it The {@link Application} instance
     *
     * @return String The formatted service prefix
     */
    def String appService(Application it) {
        vendor.formatForDB + '_' + name.formatForDB + '_module'
    }

    /**
     * Returns the lowercase application-specific prefix.
     *
     * @param it The {@link Application} instance
     *
     * @return String The prefix
     */
    def prefix(Application it) {
        prefix.formatForDB
    }

    /**
     * Checks whether a given core version is targeted or not.
     *
     * @param it The {@link Application} instance
     * @param version The version in question
     *
     * @return Boolean The result
     */
    def Boolean targets(Application it, String version) {
        val useStable15 = !#['1.5-dev', '2.0', '2.0-dev'].contains(version)

        switch targetCoreVersion {
            case ZK2DEV:
                #['2.0-dev', '2.0', '1.5-dev'].contains(version)
            case ZK20:
                #['2.0', '1.5-dev'].contains(version)
            case ZK15:
                useStable15
            case ZK15DEV:
                version == '1.5-dev'
            default:
                useStable15
        }
    }

    /**
     * Returns the core version as semantic version number.
     *
     * @param it The {@link Application} instance
     * @param withPoint Whether to include the last part or not
     *
     * @return String the formatted version number
     */
    def targetSemVer(Application it, Boolean withPoint) {
        switch targetCoreVersion {
            case ZK2DEV:
                if (!withPoint) '2.0' else '2.0.8'
            case ZK20:
                if (!withPoint) '2.0' else '2.0.7'
            case ZK15:
                if (!withPoint) '1.5' else '1.5.7'
            case ZK15DEV:
                if (!withPoint) '1.5' else '1.5.8'
            default:
                if (!withPoint) '2.0' else '2.0.7'
        }
    }

    /**
     * Checks whether any variables are part of the model or not.
     *
     * @param it The {@link Application} instance
     *
     * @return Boolean The result
     */
    def needsConfig(Application it) {
        !getAllVariables.empty
    }

    /**
     * Checks whether there exist multiple variables containers.
     *
     * @param it The {@link Application} instance
     *
     * @return Boolean The result
     */
    def hasMultipleConfigSections(Application it) {
        variables.size > 1
    }

    /**
     * Returns the variables containers sorted by their sort order.
     *
     * @param it The {@link Application} instance
     *
     * @return List<Variables> The selected list
     */
    def getSortedVariableContainers(Application it) {
        variables.sortBy[sortOrder]
    }

    /**
     * Returns all variables for a given application.
     *
     * @param it The {@link Application} instance
     *
     * @return List<Variable> The selected list
     */
    def getAllVariables(Application it) {
        variables.map[fields].flatten.toList
    }

    /**
     * Returns the current timestamp to mark the generation time.
     *
     * @return String The current timestamp
     */
    def timestamp() {
        new Date(System.currentTimeMillis).toString
    }

    /**
     * Prints a message if the current generation is not for a test.
     */
    def printIfNotTesting(String it, IMostFileSystemAccess fsa) {
        if (!(fsa instanceof MostInMemoryFileSystemAccess)) {
            println(it)
        }
    }
}
