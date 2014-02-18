package org.zikula.modulestudio.generator.exceptions

/**
 * Exception raised during model to text transformations when a resource could not be found.
 */
class M2TFailedGeneratorResourceNotFound extends ExceptionBase {

    /**
     * Constructor with given message.
     *
     * @param s The given error message.
     */
    new(String s) {
        super(s)
    }

    /**
     * Constructor without given message.
     */
    new() {
        super()
    }
}
