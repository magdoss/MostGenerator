package org.zikula.modulestudio.generator.cartridges.zclassic.controller.helper

import de.guite.modulestudio.metamodel.Application
import org.eclipse.xtext.generator.IFileSystemAccess
import org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff.FileHelper
import org.zikula.modulestudio.generator.extensions.ControllerExtensions
import org.zikula.modulestudio.generator.extensions.FormattingExtensions
import org.zikula.modulestudio.generator.extensions.ModelBehaviourExtensions
import org.zikula.modulestudio.generator.extensions.ModelExtensions
import org.zikula.modulestudio.generator.extensions.NamingExtensions
import org.zikula.modulestudio.generator.extensions.Utils

class NotificationHelper {

    extension ControllerExtensions = new ControllerExtensions
    extension FormattingExtensions = new FormattingExtensions
    extension ModelBehaviourExtensions = new ModelBehaviourExtensions
    extension ModelExtensions = new ModelExtensions
    extension NamingExtensions = new NamingExtensions
    extension Utils = new Utils

    def generate(Application it, IFileSystemAccess fsa) {
        println('Generating helper class for workflow notifications')
        val fh = new FileHelper
        generateClassPair(fsa, getAppSourceLibPath + 'Helper/NotificationHelper.php',
            fh.phpFileContent(it, notificationHelperBaseClass), fh.phpFileContent(it, notificationHelperImpl)
        )
    }

    def private notificationHelperBaseClass(Application it) '''
        namespace «appNamespace»\Helper\Base;

        use Swift_Message;
        use Symfony\Component\HttpFoundation\Request;
        use Symfony\Component\HttpFoundation\RequestStack;
        use Symfony\Component\HttpFoundation\Session\SessionInterface;
        use Symfony\Component\HttpKernel\KernelInterface;
        use Symfony\Component\Routing\RouterInterface;
        use Twig_Environment;
        use Zikula\Common\Translator\TranslatorInterface;
        use Zikula\Common\Translator\TranslatorTrait;
        use Zikula\Core\Doctrine\EntityAccess;
        use Zikula\ExtensionsModule\Api\VariableApi;
        use Zikula\GroupsModule\Entity\RepositoryInterface\GroupRepositoryInterface;
        use Zikula\MailerModule\Api\MailerApi;
        use Zikula\UsersModule\Entity\RepositoryInterface\UserRepositoryInterface;
        use «appNamespace»\Helper\WorkflowHelper;

        /**
         * Notification helper base class.
         */
        abstract class AbstractNotificationHelper
        {
            «notificationApiBaseImpl»
        }
    '''

    def private notificationApiBaseImpl(Application it) '''
        use TranslatorTrait;

        /**
         * @var SessionInterface
         */
        protected $session;

        /**
         * @var RouterInterface
         */
        protected $router;

        /**
         * @var KernelInterface
         */
        protected $kernel;

        /**
         * @var Request
         */
        protected $request;

        /**
         * @var VariableApi
         */
        protected $variableApi;

        /**
         * @var Twig_Environment
         */
        protected $templating;

        /**
         * @var MailerApi
         */
        protected $mailer;

        /**
         * @var GroupRepositoryInterface
         */
        protected $groupRepository;

        /**
         * @var UserRepositoryInterface
         */
        protected $userRepository;

        /**
         * @var WorkflowHelper
         */
        protected $workflowHelper;

        /**
         * List of notification recipients.
         *
         * @var array $recipients
         */
        protected $recipients = [];

        /**
         * Which type of recipient is used ("creator", "moderator" or "superModerator").
         *
         * @var string recipientType
         */
        protected $recipientType = '';

        /**
         * The entity which has been changed before.
         *
         * @var EntityAccess entity
         */
        protected $entity = '';

        /**
         * Name of workflow action which is being performed.
         *
         * @var string action
         */
        protected $action = '';

        /**
         * Name of the application.
         *
         * @var string
         */
        protected $name;

        /**
         * NotificationHelper constructor.
         *
         * @param KernelInterface          $kernel          Kernel service instance
         * @param TranslatorInterface      $translator      Translator service instance
         * @param SessionInterface         $session         Session service instance
         * @param Routerinterface          $router          Router service instance
         * @param RequestStack             $requestStack    RequestStack service instance
         * @param VariableApi              $variableApi     VariableApi service instance
         * @param Twig_Environment         $twig            Twig service instance
         * @param MailerApi                $mailerApi       MailerApi service instance
         * @param GroupRepositoryInterface $groupRepository GroupRepository service instance
         * @param UserRepositoryInterface  $userRepository  UserRepository service instance
         * @param WorkflowHelper           $workflowHelper  WorkflowHelper service instance
         */
        public function __construct(
            KernelInterface $kernel,
            TranslatorInterface $translator,
            SessionInterface $session,
            RouterInterface $router,
            RequestStack $requestStack,
            VariableApi $variableApi,
            Twig_Environment $twig,
            MailerApi $mailerApi,
            GroupRepositoryInterface $groupRepository,
            UserRepositoryInterface $userRepository,
            WorkflowHelper $workflowHelper)
        {
            $this->kernel = $kernel;
            $this->setTranslator($translator);
            $this->session = $session;
            $this->router = $router;
            $this->request = $requestStack->getCurrentRequest();
            $this->variableApi = $variableApi;
            $this->templating = $twig;
            $this->mailerApi = $mailerApi;
            $this->groupRepository = $groupRepository;
            $this->userRepository = $userRepository;
            $this->workflowHelper = $workflowHelper;
            $this->name = '«appName»';
        }

        «setTranslatorMethod»

        /**
         * Sends a mail to either an item's creator or a group of moderators.
         *
         * @return boolean
         */
        public function process($args)
        {
            if (!isset($args['recipientType']) || !$args['recipientType']) {
                return false;
            }

            if (!isset($args['action']) || !$args['action']) {
                return false;
            }

            if (!isset($args['entity']) || !$args['entity']) {
                return false;
            }

            $this->recipientType = $args['recipientType'];
            $this->action = $args['action'];
            $this->entity = $args['entity'];

            $this->collectRecipients();

            if (!count($this->recipients)) {
                return true;
            }

            if (null === $this->kernel->getModule('ZikulaMailerModule')) {
                $this->session->getFlashBag()->add('error', $this->__('Could not inform other persons about your amendments, because the Mailer module is not available - please contact an administrator about that!'));

                return false;
            }

            $result = $this->sendMails();

            $this->session->del($this->name . 'AdditionalNotificationRemarks');

            return $result;
        }

        /**
         * Collects the recipients.
         */
        protected function collectRecipients()
        {
            $this->recipients = [];

            if ($this->recipientType == 'moderator' || $this->recipientType == 'superModerator') {
                $objectType = $this->entity['_objectType'];
                $moderatorGroupId = $this->variableApi->get('«appName»', 'moderationGroupFor' . $objectType, 2);
                if ($this->recipientType == 'superModerator') {
                    $moderatorGroupId = $this->variableApi->get('«appName»', 'superModerationGroupFor' . $objectType, 2);
                }

                $moderatorGroup = $this->groupRepository->find($moderatorGroupId);
                if (null !== $moderatorGroup) {
                    foreach (array_keys($moderatorGroup['members']) as $uid) {
                        $this->addRecipient($uid);
                    }
                }
            } elseif ($this->recipientType == 'creator' && method_exists($entity, 'getCreatedBy')) {
                $creatorUid = $this->entity->getCreatedBy()->getUid();

                $this->addRecipient($creatorUid);
            }

            if (isset($args['debug']) && $args['debug']) {
                // add the admin, too
                $this->addRecipient(2);
            }
        }

        /**
         * Collects data for building the recipients array.
         *
         * @param $userId Id of treated user
         */
        protected function addRecipient($userId)
        {
            $user = $this->userRepository->find($userId);
            if (null === $user) {
                return;
            }

            $userAttributes = $user->getAttributes();

            $this->recipients[] = [
                'name' => isset($userAttributes['name']) && !empty($userAttributes['name']) ? $userAttributes['name'] : $user->getUname(),
                'email' => $user->getEmail()
            ];
        }

        /**
         * Performs the actual mailing.
         */
        protected function sendMails()
        {
            $objectType = $this->entity['_objectType'];
            $siteName = $this->variableApi->getSystemVar('sitename');
            $adminMail = $this->variableApi->getSystemVar('adminmail');

            $templateType = $this->recipientType == 'creator' ? 'Creator' : 'Moderator';
            $template = 'Email/notify' . ucfirst($objectType) . $templateType .  '.html.twig';

            $mailData = $this->prepareEmailData();
            $subject = $this->getMailSubject();

            // send one mail per recipient
            $totalResult = true;
            foreach ($this->recipients as $recipient) {
                if (!isset($recipient['name']) || !$recipient['name']) {
                    continue;
                }
                if (!isset($recipient['email']) || !$recipient['email']) {
                    continue;
                }

                $templateParameters = [
                    'recipient' => $recipient,
                    'mailData' => $mailData
                ];

                $body = $this->templating->render('@«appName»/' . $template, $templateParameters);
                $altBody = '';
                $html = true;

                // create new message instance
                /** @var Swift_Message */
                $message = Swift_Message::newInstance();

                $message->setFrom([$adminMail => $siteName]);
                $message->setTo([$recipient['email'] => $recipient['name']]);

                $totalResult &= $this->mailerApi->sendMessage($message, $subject, $body, $altBody, $html);
            }

            return $totalResult;
        }

        /**
         * Returns the subject used for the emails to be sent.
         *
         * @return string
         */
        protected function getMailSubject()
        {
            $mailSubject = '';
            if ($this->recipientType == 'moderator' || $this->recipientType == 'superModerator') {
                if ($this->action == 'submit') {
                    $mailSubject = $this->__('New content has been submitted');
                } elseif ($this->action == 'delete') {
                    $mailSubject = $this->__('Content has been deleted');
                } else {
                    $mailSubject = $this->__('Content has been updated');
                }
            } elseif ($this->recipientType == 'creator') {
                if ($this->action == 'delete') {
                    $mailSubject = $this->__('Your submission has been deleted');
                } else {
                    $mailSubject = $this->__('Your submission has been updated');
                }
            }

            return $mailSubject;
        }

        /**
         * Collects data used by the email templates.
         *
         * @return array
         */
        protected function prepareEmailData()
        {
            $objectType = $this->entity['_objectType'];
            $state = $this->entity['workflowState'];
            $stateInfo = $this->workflowHelper->getStateInfo($state);

            $remarks = $this->session->get($this->name . 'AdditionalNotificationRemarks', '');

            $urlArgs = $this->entity->createUrlArgs();

            $hasDisplayAction = in_array($objectType, ['«getAllEntities.filter[hasDisplayAction].map[name.formatForCode].join('\', \'')»']);
            $hasEditAction = in_array($objectType, ['«getAllEntities.filter[hasEditAction].map[name.formatForCode].join('\', \'')»']);
            $routeArea = in_array($this->recipientType, ['moderator', 'superModerator']) ? 'admin' : '';
            $routePrefix = '«appName.formatForDB»_' . strtolower($objectType) . '_' . $routeArea;

            $displayUrl = $hasDisplayAction ? $this->router->generate($routePrefix . 'display', $urlArgs, true) : '';
            $editUrl = $hasEditAction ? $this->router->generate($routePrefix . 'edit', $urlArgs, true) : '';

            $emailData = [
                'name' => $this->entity->getTitleFromDisplayPattern(),
                'newState' => $stateInfo['text'],
                'remarks' => $remarks,
                'displayUrl' => $displayUrl,
                'editUrl' => $editUrl
            ];

            return $emailData;
        }
    '''

    def private notificationHelperImpl(Application it) '''
        namespace «appNamespace»\Helper;

        use «appNamespace»\Helper\Base\AbstractNotificationHelper;

        /**
         * Notification helper implementation class.
         */
        class NotificationHelper extends AbstractNotificationHelper
        {
            // feel free to extend the notification helper here
        }
    '''
}
