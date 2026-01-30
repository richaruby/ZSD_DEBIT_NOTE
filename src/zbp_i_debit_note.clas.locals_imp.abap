CLASS lhc_ZI_DEBIT_NOTE DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_debit_note RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_debit_note RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zi_debit_note RESULT result.

    METHODS zprint FOR MODIFY
      IMPORTING keys FOR ACTION zi_debit_note~zprint RESULT result.

ENDCLASS.

CLASS lhc_ZI_DEBIT_NOTE IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD zprint.

     READ ENTITIES OF zi_debit_note IN LOCAL MODE
    ENTITY zi_debit_note
    ALL FIELDS WITH CORRESPONDING #( keys )
           RESULT DATA(lt_result).
    DATA : update_lines TYPE TABLE FOR UPDATE zi_debit_note,
           update_line  TYPE STRUCTURE FOR UPDATE zi_debit_note.

    LOOP AT lt_result INTO DATA(lw_result).



      update_line-%tky                   = lw_result-%tky.
      update_line-base64                 = 'A'.

      IF update_line-base64 IS NOT INITIAL.

        APPEND update_line TO update_lines.

        MODIFY ENTITIES OF zi_debit_note IN LOCAL MODE
ENTITY zi_debit_note
UPDATE
FIELDS ( base64 )
WITH update_lines
REPORTED reported
FAILED failed
MAPPED mapped.


        READ ENTITIES OF zi_debit_note IN LOCAL MODE  ENTITY zi_debit_note
    ALL FIELDS WITH CORRESPONDING #( lt_result ) RESULT DATA(lt_final).

        APPEND VALUE #( %tky = keys[ 1 ]-%tky
               %msg = new_message_with_text(
               severity = if_abap_behv_message=>severity-success
               text = 'PDF Generated!' )
                ) TO reported-zi_debit_note.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_DEBIT_NOTE DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_DEBIT_NOTE IMPLEMENTATION.

  METHOD save_modified.

  DATA background_process TYPE REF TO if_bgmc_process_single_op.

    IF update-zi_debit_note IS NOT INITIAL.

      LOOP AT update-zi_debit_note INTO DATA(ls_data).
        DATA(new) = NEW zcl_debit_note_preview( iv_bukrs = ls_data-bukrs
                                             iv_belnr = ls_data-belnr
                                             iv_gjahr = ls_data-gjahr ).

        TRY.

            background_process = cl_bgmc_process_factory=>get_default( )->create( ).

            background_process->set_operation_tx_uncontrolled( new ).

            background_process->save_for_execution( ).

          CATCH cx_bgmc INTO DATA(exception).
            "handle exception
        ENDTRY.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
