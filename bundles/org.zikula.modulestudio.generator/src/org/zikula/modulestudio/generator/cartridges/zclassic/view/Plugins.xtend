package org.zikula.modulestudio.generator.cartridges.zclassic.view

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.DateField
import de.guite.modulestudio.metamodel.TimeField
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.ActionUrl
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.FormatGeoData
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.FormatIcalText
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.GetCountryName
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.GetFileSize
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.GetListEntry
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.ModerationObjects
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.ObjectState
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.ObjectTypeSelector
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.TemplateHeaders
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.TemplateSelector
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.TreeData
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.TreeSelection
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.ValidationError
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.AbstractObjectSelector
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.ColourInput
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.CountrySelector
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.DateInput
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.Frame
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.GeoInput
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.ItemSelector
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.RelationSelectorAutoComplete
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.RelationSelectorList
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.TimeInput
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.TreeSelector
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.UserInput
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.WorkflowExtensions

class Plugins {
    extension ControllerExtensions = new ControllerExtensions
    extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelExtensions = new ModelExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils
    extension WorkflowExtensions = new WorkflowExtensions

    IFileSystemAccess fsa

    def generate(Application it, IFileSystemAccess fsa) {
        this.fsa = fsa
        if (!targets('1.3.x')) {
            println('Generating Twig extension class')
            val fh = new FileHelper
            val twigFolder = 'Twig'
            generateClassPair(fsa, getAppSourceLibPath + twigFolder + '/TwigExtension.php',
                fh.phpFileContent(it, twigExtensionBaseImpl), fh.phpFileContent(it, twigExtensionImpl)
            )
        } else {
            generateInternal
        }
    }

    def generateInternal(Application it) {
        val result = newArrayList
        result += viewPlugins
        if (targets('1.3.x')) {
            if (hasEditActions || needsConfig) {
                new Frame().generate(it, fsa)
            }
        } else {
            // content type editing is not ready for Twig yet
            if (generateListContentType || generateDetailContentType) {
                new ObjectTypeSelector().generate(it, fsa, true)
            }
            if (generateListContentType) {
                new TemplateSelector().generate(it, fsa, true)
            }
            if (generateDetailContentType) {
                new ItemSelector().generate(it, fsa)
            }
        }
        if (hasEditActions && targets('1.3.x')) {
            editPlugins
            new ValidationError().generate(it, fsa)
        }
        result += otherPlugins
        result.join("\n\n")
    }

    // 1.4.x only
    def private twigExtensionBaseImpl(Application it) '''
        namespace «appNamespace»\Twig\Base;

        «IF hasTrees»
            use Symfony\Component\Routing\RouterInterface;
        «ENDIF»
        use Zikula\Common\Translator\TranslatorInterface;
        use Zikula\Common\Translator\TranslatorTrait;
        use Zikula\ExtensionsModule\Api\VariableApi;
        use «appNamespace»\Helper\WorkflowHelper;
        «IF hasUploads»
            use «appNamespace»\Helper\ViewHelper;
        «ENDIF»
        «IF hasListFields»
            use «appNamespace»\Helper\ListEntriesHelper;
        «ENDIF»

        /**
         * Twig extension base class.
         */
        class TwigExtension extends \Twig_Extension
        {
            «twigExtensionBody»
        }
    '''

    // 1.4.x only
    def private twigExtensionBody(Application it) '''
        «val appNameLower = appName.toLowerCase»
        use TranslatorTrait;

        «IF hasTrees»
            /**
             * @var RouterInterface
             */
            protected $router;

        «ENDIF»
        /**
         * @var VariableApi
         */
        protected $variableApi;

        /**
         * @var WorkflowHelper
         */
        protected $workflowHelper;

        «IF hasUploads»
            /**
             * @var ViewHelper
             */
            protected $viewHelper;

        «ENDIF»
        «IF hasListFields»
            /**
             * @var ListEntriesHelper
             */
            protected $listHelper;

        «ENDIF»
        /**
         * Constructor.
         * Initialises member vars.
         *
         * @param TranslatorInterface $translator     Translator service instance
        «IF hasTrees»
            «' '»* @param Routerinterface     $router         Router service instance
        «ENDIF»
         * @param VariableApi         $variableApi    VariableApi service instance
         * @param WorkflowHelper      $workflowHelper WorkflowHelper service instance
        «IF hasUploads»
            «' '»* @param ViewHelper          $viewHelper     ViewHelper service instance
        «ENDIF»
        «IF hasListFields»
            «' '»* @param ListEntriesHelper   $listHelper     ListEntriesHelper service instance
        «ENDIF»
         */
        public function __construct(TranslatorInterface $translator«IF hasTrees», RouterInterface $router«ENDIF», VariableApi $variableApi, WorkflowHelper $workflowHelper«IF hasUploads», ViewHelper $viewHelper«ENDIF»«IF hasListFields», ListEntriesHelper $listHelper«ENDIF»)
        {
            $this->setTranslator($translator);
            «IF hasTrees»
                $this->router = $router;
            «ENDIF»
            $this->variableApi = $variableApi;
            $this->workflowHelper = $workflowHelper;
            «IF hasUploads»
                $this->viewHelper = $viewHelper;
            «ENDIF»
            «IF hasListFields»
                $this->listHelper = $listHelper;
            «ENDIF»
        }

        /**
         * Sets the translator.
         *
         * @param TranslatorInterface $translator Translator service instance
         */
        public function setTranslator(/*TranslatorInterface */$translator)
        {
            $this->translator = $translator;
        }

        /**
         * Returns a list of custom Twig functions.
         *
         * @return array
         */
        public function getFunctions()
        {
            return [
                new \Twig_SimpleFunction('«appNameLower»_templateHeaders', [$this, 'templateHeaders']),
                «IF hasTrees»
                    new \Twig_SimpleFunction('«appNameLower»_treeData', [$this, 'getTreeData']),
                    new \Twig_SimpleFunction('«appNameLower»_treeSelection', [$this, 'getTreeSelection']),
                «ENDIF»
                «IF generateModerationPanel && needsApproval»
                    new \Twig_SimpleFunction('«appNameLower»_moderationObjects', [$this, 'getModerationObjects']),
                «ENDIF»
                new \Twig_SimpleFunction('«appNameLower»_objectTypeSelector', [$this, 'getObjectTypeSelector']),
                new \Twig_SimpleFunction('«appNameLower»_templateSelector', [$this, 'getTemplateSelector']),
                new \Twig_SimpleFunction('«appNameLower»_userVar', [$this, 'getUserVar']),
                new \Twig_SimpleFunction('«appNameLower»_userAvatar', [$this, 'getUserAvatar']),
                new \Twig_SimpleFunction('«appNameLower»_thumb', [$this, 'getImageThumb'])
            ];
        }

        /**
         * Returns a list of custom Twig filters.
         *
         * @return array
         */
        public function getFilters()
        {
            return [
                new \Twig_SimpleFilter('«appNameLower»_actionUrl', [$this, 'buildActionUrl']),
                new \Twig_SimpleFilter('«appNameLower»_objectState', [$this, 'getObjectState']),
                «IF hasCountryFields»
                    new \Twig_SimpleFilter('«appNameLower»_countryName', [$this, 'getCountryName']),
                «ENDIF»
                «IF hasUploads»
                    new \Twig_SimpleFilter('«appNameLower»_fileSize', [$this, 'getFileSize']),
                «ENDIF»
                «IF hasListFields»
                    new \Twig_SimpleFilter('«appNameLower»_listEntry', [$this, 'getListEntry']),
                «ENDIF»
                «IF hasGeographical»
                    new \Twig_SimpleFilter('«appNameLower»_geoData', [$this, 'formatGeoData']),
                «ENDIF»
                «IF (generateIcsTemplates && !entities.filter[null !== startDateField && null !== endDateField].empty)»
                    new \Twig_SimpleFilter('«appNameLower»_icalText', [$this, 'formatIcalText']),
                «ENDIF»
                new \Twig_SimpleFilter('«appNameLower»_profileLink', [$this, 'profileLink'])
            ];
        }

        «generateInternal»

        «twigExtensionCompat»

        /**
         * Returns internal name of this extension.
         *
         * @return string
         */
        public function getName()
        {
            return '«appName.formatForDB»_twigextension';
        }
    '''

    // 1.4.x only
    def private twigExtensionCompat(Application it) '''
        /**
         * Returns the value of a user variable.
         *
         * @param string     $name    Name of desired property
         * @param int        $uid     The user's id
         * @param string|int $default The default value
         *
         * @return string
         */
        public function getUserVar($name, $uid = -1, $default = '')
        {
            if (!$uid) {
                $uid = -1;
            }

            $result = \UserUtil::getVar($name, $uid, $default);

            return $result;
        }

        /**
         * Display the avatar of a user.
         *
         * @param int    $uid    The user's id
         * @param int    $width  Image width (optional)
         * @param int    $height Image height (optional)
         * @param int    $size   Gravatar size (optional)
         * @param string $rating Gravatar self-rating [g|pg|r|x] see: http://en.gravatar.com/site/implement/images/ (optional)
         *
         * @return string
         */
        public function getUserAvatar($uid, $width = 0, $height = 0, $size = 0, $rating = '')
        {
            $params = ['uid' => $uid];
            if ($width > 0) {
                $params['width'] = $width;
            }
            if ($height > 0) {
                $params['height'] = $height;
            }
            if ($size > 0) {
                $params['size'] = $size;
            }
            if ($rating != '') {
                $params['rating'] = $rating;
            }

            include_once 'lib/legacy/viewplugins/function.useravatar.php';

            $view = \Zikula_View::getInstance('«appName»');
            $result = smarty_function_useravatar($params, $view);

            return $result;
        }

        /**
         * Display an image thumbnail using Imagine system plugin.
         *
         * @param array $params Parameters assigned to bridged Smarty plugin
         *
         * @return string Thumb path
         */
        public function getImageThumb($params)
        {
            include_once 'plugins/Imagine/templates/plugins/function.thumb.php';

            $view = \Zikula_View::getInstance('«appName»');
            $result = smarty_function_thumb($params, $view);

            return $result;
        }

        /**
         * Returns a link to the user's profile.
         *
         * @param int     $uid       The user's id (optional)
         * @param string  $class     The class name for the link (optional)
         * @param integer $maxLength If set then user names are truncated to x chars
         *
         * @return string
         */
        public function profileLink($uid, $class = '', $maxLength = 0)
        {
            $result = '';
            $image = '';

            if ($uid == '') {
                return $result;
            }

            if ($this->variableApi->get(VariableApi::CONFIG, 'profilemodule') != '') {
                include_once 'lib/legacy/viewplugins/modifier.profilelinkbyuid.php';
                $result = smarty_modifier_profilelinkbyuid($uid, $class, $image, $maxLength);
            } else {
                $result = \UserUtil::getVar('uname', $uid);
            }

            return $result;
        }
    '''

    // 1.4.x only
    def private twigExtensionImpl(Application it) '''
        namespace «appNamespace»\Twig;

        use «appNamespace»\Twig\Base\TwigExtension as BaseTwigExtension;

        /**
         * Twig extension implementation class.
         */
        class TwigExtension extends BaseTwigExtension
        {
            // feel free to add your own Twig extension methods here
        }
    '''

    def private viewPlugins(Application it) {
        val result = newArrayList
        result += new ActionUrl().generate(it, fsa)
        result += new ObjectState().generate(it, fsa)
        result += new TemplateHeaders().generate(it, fsa)
        if (hasCountryFields) {
            result += new GetCountryName().generate(it, fsa)
        }
        if (hasUploads) {
            result += new GetFileSize().generate(it, fsa)
        }
        if (hasListFields) {
            result += new GetListEntry().generate(it, fsa)
        }
        if (hasGeographical) {
            result += new FormatGeoData().generate(it, fsa)
        }
        if (hasTrees) {
            result += new TreeData().generate(it, fsa)
            result += new TreeSelection().generate(it, fsa)
        }
        if (generateModerationPanel && needsApproval) {
            result += new ModerationObjects().generate(it, fsa)
        }
        if (generateIcsTemplates && !entities.filter[null !== startDateField && null !== endDateField].empty) {
            result += new FormatIcalText().generate(it, fsa)
        }
        result.join("\n\n")
    }

    def private editPlugins(Application it) {
        if (!targets('1.3.x')) {
            return
        }

        if (hasColourFields) {
            new ColourInput().generate(it, fsa)
        }
        if (hasCountryFields) {
            new CountrySelector().generate(it, fsa)
        }
        if (hasGeographical) {
            new GeoInput().generate(it, fsa)
        }
        if (!entities.filter[!fields.filter(DateField).empty].empty) {
            new DateInput().generate(it, fsa)
        }
        if (!entities.filter[!fields.filter(TimeField).empty].empty) {
            new TimeInput().generate(it, fsa)
        }

        val hasRelations = !relations.empty
        if (hasTrees || hasRelations) {
            new AbstractObjectSelector().generate(it, fsa)
        }
        if (hasTrees) {
            new TreeSelector().generate(it, fsa)
        }
        if (hasRelations) {
            new RelationSelectorList().generate(it, fsa)
            new RelationSelectorAutoComplete().generate(it, fsa)
        }
        if (hasUserFields) {
            new UserInput().generate(it, fsa)
        }
    }

    def private otherPlugins(Application it) {
        val result = newArrayList
        if (generateDetailContentType) {
            new ItemSelector().generate(it, fsa)
        }
        result += new ObjectTypeSelector().generate(it, fsa, false)
        result += new TemplateSelector().generate(it, fsa, false)
        result.join("\n\n")
    }
}