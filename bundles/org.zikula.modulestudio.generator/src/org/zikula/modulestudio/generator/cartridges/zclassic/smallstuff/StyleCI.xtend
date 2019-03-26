package org.zikula.modulestudio.generator.cartridges.zclassic.smallstuff

import de.guite.modulestudio.metamodel.Application
import org.zikula.modulestudio.generator.application.IMostFileSystemAccess

class StyleCI {

    def generate(Application it, IMostFileSystemAccess fsa) {
        fsa.generateFile('.styleci.yml', styleci)
    }

    def private styleci(Application it) '''
        preset: symfony

        enabled:
          - alpha_ordered_imports
          - combine_consecutive_issets
          - combine_consecutive_unsets
          - compact_nullable_typehint
          - declare_strict_types
          - dir_constant
          - ereg_to_preg
          - escape_implicit_backslashes
          - explicit_indirect_variable
          - explicit_string_variable
          - fully_qualified_strict_types
          - mb_str_functions
          - modernize_types_casting
          - multiline_comment_opening_closing
          - no_alternative_syntax
          - no_null_property_initialization
          - no_php4_constructor
          - no_short_echo_tag
          - no_unneeded_curly_braces
          - no_unneeded_final_method
          - no_useless_else
          - non_printable_character
          - php_unit_mock
          - php_unit_namespaced
          - php_unit_set_up_tear_down_visibility
          - random_api_migration
          - short_array_syntax
          - standardize_increment
          - strict_comparison
          - ternary_to_null_coalescing

        disabled:
          - blank_line_before_break
          - blank_line_before_continue
          - blank_line_before_declare
          - blank_line_before_throw
          - blank_line_before_try
          - cast_spaces
          - concat_without_spaces
          - function_declaration
          - no_blank_lines_after_phpdoc
          - no_blank_lines_after_throw
          - php_unit_fqcn_annotation
          - phpdoc_align
          - phpdoc_no_empty_return
          - phpdoc_scalar
          - phpdoc_separation
          - phpdoc_summary
          - phpdoc_to_comment
          - pre_increment
          - self_accessor
          - single_quote
          - trailing_comma_in_multiline_array
          - unalign_double_arrow
          - unalign_equals
    '''
}
