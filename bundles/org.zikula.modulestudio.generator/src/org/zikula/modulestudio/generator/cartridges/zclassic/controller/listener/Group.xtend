package org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener

import de.guite.modulestudio.metamodel.Application

class Group {

    CommonExample commonExample = new CommonExample()

    def generate(Application it) '''
        /**
         * Makes our handlers known to the event system.
         */
        public static function getSubscribedEvents()
        {
            return [
                GroupEvents::GROUP_CREATE                => ['create', 5],
                GroupEvents::GROUP_UPDATE                => ['update', 5],
                GroupEvents::GROUP_DELETE                => ['delete', 5],
                GroupEvents::GROUP_ADD_USER              => ['addUser', 5],
                GroupEvents::GROUP_REMOVE_USER           => ['removeUser', 5],
                GroupEvents::GROUP_APPLICATION_PROCESSED => ['applicationProcessed', 5],
                GroupEvents::GROUP_NEW_APPLICATION       => ['newApplication', 5]
            ];
        }

        /**
         * Listener for the `group.create` event.
         *
         * Occurs after a group is created. All handlers are notified.
         * The full group record created is available as the subject.
         *
         «commonExample.generalEventProperties(it, false)»
         * @param GenericEvent $event The event instance
         */
        public function create(GenericEvent $event)
        {
        }

        /**
         * Listener for the `group.update` event.
         *
         * Occurs after a group is updated. All handlers are notified.
         * The full updated group record is available as the subject.
         *
         «commonExample.generalEventProperties(it, false)»
         * @param GenericEvent $event The event instance
         */
        public function update(GenericEvent $event)
        {
        }

        /**
         * Listener for the `group.delete` event.
         *
         * Occurs after a group is deleted from the system. All handlers are notified.
         * The full group record deleted is available as the subject.
         *
         «commonExample.generalEventProperties(it, false)»
         * @param GenericEvent $event The event instance
         */
        public function delete(GenericEvent $event)
        {
        }

        /**
         * Listener for the `group.adduser` event.
         *
         * Occurs after a user is added to a group. All handlers are notified.
         * It does not apply to pending membership requests.
         * The uid and gid are available as the subject.
         *
         «commonExample.generalEventProperties(it, false)»
         * @param GenericEvent $event The event instance
         */
        public function addUser(GenericEvent $event)
        {
        }

        /**
         * Listener for the `group.removeuser` event.
         *
         * Occurs after a user is removed from a group. All handlers are notified.
         * The uid and gid are available as the subject.
         *
         «commonExample.generalEventProperties(it, false)»
         * @param GenericEvent $event The event instance
         */
        public function removeUser(GenericEvent $event)
        {
        }

        /**
         * Listener for the `group.application.processed` event.
         *
         * Occurs after a group application has been processed.
         * The subject is the GroupApplicationEntity.
         * Arguments are the form data from \Zikula\GroupsModule\Form\Type\ManageApplicationType
         *
         «commonExample.generalEventProperties(it, false)»
         * @param GenericEvent $event The event instance
         */
        public function applicationProcessed(GenericEvent $event)
        {
        }

        /**
         * Listener for the `group.application.new` event.
         *
         * Occurs after the successful creation of a group application.
         * The subject is the GroupApplicationEntity.
         *
         «commonExample.generalEventProperties(it, false)»
         * @param GenericEvent $event The event instance
         */
        public function newApplication(GenericEvent $event)
        {
        }
    '''
}
