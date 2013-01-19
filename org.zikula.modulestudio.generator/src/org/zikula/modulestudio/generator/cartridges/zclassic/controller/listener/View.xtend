package org.zikula.modulestudio.generator.cartridges.zclassic.controller.listener

import com.google.inject.Inject
import de.guite.modulestudio.metamodel.modulestudio.Application
import org.zikula.modulestudio.generator.extensions.Utils

class View {
    @Inject extension Utils = new Utils()

    def generate(Application it, Boolean isBase) '''
        /**
         * Listener for the `view.init` event.
         *
         * Occurs just before `Zikula_View#__construct()` finishes.
         * The subject is the Zikula_View instance.
         *
         * @param «IF targets('1.3.5')»Zikula_Event«ELSE»Zikula\Core\Event\GenericEvent«ENDIF» $event The event instance.
         */
        public static function init(«IF targets('1.3.5')»Zikula_Event«ELSE»Zikula\Core\Event\GenericEvent«ENDIF» $event)
        {
            «IF !isBase»
                parent::init($event);
            «ENDIF»
        }

        /**
         * Listener for the `view.postfetch` event.
         *
         * Filter of result of a fetch.
         * Receives `Zikula_View` instance as subject,
         * args are `array('template' => $template)`,
         * $data was the result of the fetch to be filtered.
         *
         * @param «IF targets('1.3.5')»Zikula_Event«ELSE»Zikula\Core\Event\GenericEvent«ENDIF» $event The event instance.
         */
        public static function postFetch(«IF targets('1.3.5')»Zikula_Event«ELSE»Zikula\Core\Event\GenericEvent«ENDIF» $event)
        {
            «IF !isBase»
                parent::postFetch($event);
            «ENDIF»
        }
    '''
}
