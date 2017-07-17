package org.zikula.modulestudio.generator.cartridges.zclassic.view

import de.guite.modulestudio.metamodel.Application
import de.guite.modulestudio.metamodel.StringField
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.FormatGeoData
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.FormatIcalText
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.GetCountryName
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.GetFileSize
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.GetListEntry
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.ModerationObjects
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.ObjectState
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.ObjectTypeSelector
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.TemplateSelector
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.TreeData
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.TreeSelection
import org.zikula.modulestudio.generator.cartridges.zclassic.view.plugin.form.ItemSelector
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.GeneratorSettingsExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils
import org.zikula.modulestudio.generator.extensions.WorkflowExtensions

class Plugins {

    extension FormattingExtensions = new FormattingExtensions
    extension GeneratorSettingsExtensions = new GeneratorSettingsExtensions
    extension ModelExtensions = new ModelExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils
    extension WorkflowExtensions = new WorkflowExtensions

    IFileSystemAccess fsa

    def generate(Application it, IFileSystemAccess fsa) {
        this.fsa = fsa
        println('Generating Twig extension class')
        val fh = new FileHelper
        val twigFolder = 'Twig'
        generateClassPair(fsa, getAppSourceLibPath + twigFolder + '/TwigExtension.php',
            fh.phpFileContent(it, twigExtensionBaseImpl), fh.phpFileContent(it, twigExtensionImpl)
        )
    }

    def generateInternal(Application it) {
        val result = newArrayList
        result += viewPlugins
        if (!targets('2.0')) {
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
        result += otherPlugins
        result.join("\n\n")
    }

    def private twigExtensionBaseImpl(Application it) '''
        namespace «appNamespace»\Twig\Base;

        «IF targets('2.0') && !getAllEntities.filter[!fields.filter(StringField).filter[dateInterval].empty].empty»
            use DateInterval;
        «ENDIF»
        «IF generateIcsTemplates && hasEntitiesWithIcsTemplates»
            use Symfony\Component\HttpFoundation\Request;
            use Symfony\Component\HttpFoundation\RequestStack;
        «ENDIF»
        «IF hasTrees»
            use Symfony\Component\Routing\RouterInterface;
        «ENDIF»
        use Twig_Extension;
        use Zikula\Common\Translator\TranslatorInterface;
        use Zikula\Common\Translator\TranslatorTrait;
        use Zikula\ExtensionsModule\Api\«IF targets('1.5')»ApiInterface\VariableApiInterface«ELSE»VariableApi«ENDIF»;
        «IF needsUserAvatarSupport»
            use Zikula\UsersModule\Constant as UsersConstant;
            use Zikula\UsersModule\Entity\RepositoryInterface\UserRepositoryInterface;
        «ENDIF»
        «IF hasTrees»
            use «appNamespace»\Entity\Factory\EntityFactory;
        «ENDIF»
        «IF hasListFields»
            use «appNamespace»\Helper\ListEntriesHelper;
        «ENDIF»
        use «appNamespace»\Helper\EntityDisplayHelper;
        use «appNamespace»\Helper\WorkflowHelper;

        /**
         * Twig extension base class.
         */
        abstract class AbstractTwigExtension extends Twig_Extension
        {
            «twigExtensionBody»
        }
    '''

    def private twigExtensionBody(Application it) '''
        «val appNameLower = appName.toLowerCase»
        use TranslatorTrait;

        «IF hasTrees»
            /**
             * @var RouterInterface
             */
            protected $router;

        «ENDIF»
        «IF generateIcsTemplates && hasEntitiesWithIcsTemplates»
            /**
             * @var Request
             */
            protected $request;

        «ENDIF»
        /**
         * @var VariableApi«IF targets('1.5')»Interface«ENDIF»
         */
        protected $variableApi;

        «IF needsUserAvatarSupport»
            /**
             * @var UserRepositoryInterface
             */
            protected $userRepository;

        «ENDIF»
        «IF hasTrees»
            /**
             * @var EntityFactory
             */
            protected $entityFactory;

        «ENDIF»
        /**
         * @var EntityDisplayHelper
         */
        protected $entityDisplayHelper;

        /**
         * @var WorkflowHelper
         */
        protected $workflowHelper;

        «IF hasListFields»
            /**
             * @var ListEntriesHelper
             */
            protected $listHelper;

        «ENDIF»
        /**
         * TwigExtension constructor.
         *
         * @param TranslatorInterface $translator     Translator service instance
         «IF hasTrees»
            * @param Routerinterface     $router         Router service instance
         «ENDIF»
         «IF generateIcsTemplates && hasEntitiesWithIcsTemplates»
            * @param RequestStack        $requestStack   RequestStack service instance
         «ENDIF»
         * @param VariableApi«IF targets('1.5')»Interface«ELSE»        «ENDIF» $variableApi    VariableApi service instance
         «IF needsUserAvatarSupport»
            * @param UserRepositoryInterface $userRepository UserRepository service instance
         «ENDIF»
         «IF hasTrees»
         * @param EntityFactory       $entityFactory     EntityFactory service instance
         «ENDIF»
         * @param EntityDisplayHelper $entityDisplayHelper EntityDisplayHelper service instance
         * @param WorkflowHelper      $workflowHelper WorkflowHelper service instance
         «IF hasListFields»
            * @param ListEntriesHelper   $listHelper     ListEntriesHelper service instance
         «ENDIF»
         */
        public function __construct(
            TranslatorInterface $translator«IF hasTrees»,
            RouterInterface $router«ENDIF»«IF generateIcsTemplates && hasEntitiesWithIcsTemplates»,
            RequestStack $requestStack«ENDIF»,
            VariableApi«IF targets('1.5')»Interface«ENDIF» $variableApi,
            «IF needsUserAvatarSupport»
                UserRepositoryInterface $userRepository,
            «ENDIF»
            «IF hasTrees»
                EntityFactory $entityFactory,
            «ENDIF»
            EntityDisplayHelper $entityDisplayHelper,
            WorkflowHelper $workflowHelper«IF hasListFields»,
            ListEntriesHelper $listHelper«ENDIF»)
        {
            $this->setTranslator($translator);
            «IF hasTrees»
                $this->router = $router;
            «ENDIF»
            «IF generateIcsTemplates && hasEntitiesWithIcsTemplates»
                $this->request = $requestStack->getCurrentRequest();
            «ENDIF»
            $this->variableApi = $variableApi;
            «IF needsUserAvatarSupport»
                $this->userRepository = $userRepository;
            «ENDIF»
            «IF hasTrees»
                $this->entityFactory = $entityFactory;
            «ENDIF»
            $this->entityDisplayHelper = $entityDisplayHelper;
            $this->workflowHelper = $workflowHelper;
            «IF hasListFields»
                $this->listHelper = $listHelper;
            «ENDIF»
        }

        «setTranslatorMethod»

        /**
         * Returns a list of custom Twig functions.
         *
         * @return \Twig_SimpleFunction[]
         */
        public function getFunctions()
        {
            return [
                «IF hasTrees»
                    new \Twig_SimpleFunction('«appNameLower»_treeData', [$this, 'getTreeData'], ['is_safe' => ['html']]),
                    new \Twig_SimpleFunction('«appNameLower»_treeSelection', [$this, 'getTreeSelection']),
                «ENDIF»
                «IF generateModerationPanel && needsApproval»
                    new \Twig_SimpleFunction('«appNameLower»_moderationObjects', [$this, 'getModerationObjects']),
                «ENDIF»
                new \Twig_SimpleFunction('«appNameLower»_objectTypeSelector', [$this, 'getObjectTypeSelector']),
                new \Twig_SimpleFunction('«appNameLower»_templateSelector', [$this, 'getTemplateSelector'])«IF needsUserAvatarSupport»,
                new \Twig_SimpleFunction('«appNameLower»_userAvatar', [$this, 'getUserAvatar'], ['is_safe' => ['html']])«ENDIF»
            ];
        }

        /**
         * Returns a list of custom Twig filters.
         *
         * @return \Twig_SimpleFilter[]
         */
        public function getFilters()
        {
            return [
                «IF hasCountryFields»
                    new \Twig_SimpleFilter('«appNameLower»_countryName', [$this, 'getCountryName']),
                «ENDIF»
                «IF targets('2.0') && !getAllEntities.filter[!fields.filter(StringField).filter[dateInterval].empty].empty»
                    new \Twig_SimpleFilter('«appNameLower»_dateInterval', [$this, 'getFormattedDateInterval']),
                «ENDIF»
                «IF hasUploads»
                    new \Twig_SimpleFilter('«appNameLower»_fileSize', [$this, 'getFileSize'], ['is_safe' => ['html']]),
                «ENDIF»
                «IF hasListFields»
                    new \Twig_SimpleFilter('«appNameLower»_listEntry', [$this, 'getListEntry']),
                «ENDIF»
                «IF hasGeographical»
                    new \Twig_SimpleFilter('«appNameLower»_geoData', [$this, 'formatGeoData']),
                «ENDIF»
                «IF hasEntitiesWithIcsTemplates»
                    new \Twig_SimpleFilter('«appNameLower»_icalText', [$this, 'formatIcalText']),
                «ENDIF»
                new \Twig_SimpleFilter('«appNameLower»_formattedTitle', [$this, 'getFormattedEntityTitle']),
                new \Twig_SimpleFilter('«appNameLower»_objectState', [$this, 'getObjectState'], ['is_safe' => ['html']])
            ];
        }
        «IF hasLoggable»

            /**
             * Returns a list of custom Twig tests.
             *
             * @return array
             */
            public function getTests()
            {
                return [
                    new \Twig_SimpleTest('«appNameLower»_instanceOf', function ($var, $instance) {
                        return $var instanceof $instance;
                    })
                ];
            }
        «ENDIF»

        «generateInternal»
        «IF targets('2.0') && !getAllEntities.filter[!fields.filter(StringField).filter[dateInterval].empty].empty»

            /**
             * The «appName.formatForDB»_dateInterval filter outputs a formatted description for a given date interval (duration string).
             * Example:
             *     {{ myDateIntervalString|«appName.formatForDB»_dateInterval }}
             *
             * @see http://php.net/manual/en/dateinterval.format.php
             *
             * @param object $duration The given duration string
             *
             * @return string The formatted title
             */
            public function getFormattedDateInterval($duration)
            {
                $interval = new DateInterval($duration);

                $description = $interval->invert == 1 ? '- ' : '';

                $amount = $interval->y;
                if ($amount > 0) {
                    $description .= $this->_fn('%amount year', '%amount years', $amount, ['%amount' => $amount]);
                }

                $amount = $interval->m;
                if ($amount > 0) {
                    $description .= ', ' . $this->_fn('%amount month', '%amount months', $amount, ['%amount' => $amount]);
                }

                $amount = $interval->d;
                if ($amount > 0) {
                    $description .= ', ' . $this->_fn('%amount day', '%amount days', $amount, ['%amount' => $amount]);
                }

                $amount = $interval->h;
                if ($amount > 0) {
                    $description .= ', ' . $this->_fn('%amount hour', '%amount hours', $amount, ['%amount' => $amount]);
                }

                $amount = $interval->i;
                if ($amount > 0) {
                    $description .= ', ' . $this->_fn('%amount minute', '%amount minutes', $amount, ['%amount' => $amount]);
                }

                $amount = $interval->s;
                if ($amount > 0) {
                    $description .= ', ' . $this->_fn('%amount second', '%amount seconds', $amount, ['%amount' => $amount]);
                }

                return $description;
            }
        «ENDIF»

        /**
         * The «appName.formatForDB»_formattedTitle filter outputs a formatted title for a given entity.
         * Example:
         *     {{ myPost|«appName.formatForDB»_formattedTitle }}
         *
         * @param object $entity The given entity instance
         *
         * @return string The formatted title
         */
        public function getFormattedEntityTitle($entity)
        {
            return $this->entityDisplayHelper->getFormattedTitle($entity);
        }
        «IF needsUserAvatarSupport»

            «getUserAvatar»
        «ENDIF»
    '''

    def private getUserAvatar(Application it) '''
        /**
         * Displays the avatar of a given user.
         *
         * @param int|string $uid    The user's id or name
         * @param int        $width  Image width (optional)
         * @param int        $height Image height (optional)
         * @param int        $size   Gravatar size (optional)
         * @param string     $rating Gravatar self-rating [g|pg|r|x] see: http://en.gravatar.com/site/implement/images/ (optional)
         *
         * @return string
         */
        public function getUserAvatar($uid = 0, $width = 0, $height = 0, $size = 0, $rating = '')
        {
            if (!is_numeric($uid)) {
                $limit = 1;
                $filter = [
                    'activated' => ['operator' => 'notIn', 'operand' => [
                        UsersConstant::ACTIVATED_PENDING_REG,
                        UsersConstant::ACTIVATED_PENDING_DELETE
                    ]],
                    'uname' => ['operator' => '=', 'operand' => $uid]
                ];
                $results = $this->userRepository->query($filter, [], $limit);
                if (!count($results)) {
                    return '';
                }

                $uid = $results->getIterator()->getArrayCopy()[0]->getUid();
            }
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

            // load avatar plugin
            include_once 'lib/legacy/viewplugins/function.useravatar.php';

            $view = \Zikula_View::getInstance('«appName»', false);
            $result = smarty_function_useravatar($params, $view);

            return $result;
        }
    '''

    def private twigExtensionImpl(Application it) '''
        namespace «appNamespace»\Twig;

        use «appNamespace»\Twig\Base\AbstractTwigExtension;

        /**
         * Twig extension implementation class.
         */
        class TwigExtension extends AbstractTwigExtension
        {
            // feel free to add your own Twig extension methods here
        }
    '''

    def private viewPlugins(Application it) {
        val result = newArrayList
        result += new ObjectState().generate(it, fsa)
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
        if (generateIcsTemplates && hasEntitiesWithIcsTemplates) {
            result += new FormatIcalText().generate(it, fsa)
        }
        result.join("\n\n")
    }

    def private otherPlugins(Application it) {
        val result = newArrayList
        if (generateDetailContentType && !targets('2.0')) {
            new ItemSelector().generate(it, fsa)
        }
        result += new ObjectTypeSelector().generate(it, fsa, false)
        result += new TemplateSelector().generate(it, fsa, false)
        result.join("\n\n")
    }
}
