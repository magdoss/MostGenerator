package org.zikula.modulestudio.generator.beautifier.pdt.internal.core.format;

/*******************************************************************************
 * Copyright (c) 2009 IBM Corporation and others. All rights reserved. This
 * program and the accompanying materials are made available under the terms of
 * the Eclipse Public License v1.0 which accompanies this distribution, and is
 * available at http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors: IBM Corporation - initial API and implementation Zend
 * Technologies
 * 
 * 
 * 
 * Based on package org.eclipse.php.internal.core.format;
 * 
 *******************************************************************************/

import org.eclipse.wst.sse.core.internal.provisional.text.IStructuredDocument;

/**
 * @author seva
 * 
 */
public class PHPCloseTagIndentationStrategy extends DefaultIndentationStrategy {
    @Override
    public void placeMatchingBlanks(final IStructuredDocument document,
            final StringBuffer result, final int lineNumber, final int forOffset) {
        // Ignore default behavior (don't add previous line's blanks)
    }

}
