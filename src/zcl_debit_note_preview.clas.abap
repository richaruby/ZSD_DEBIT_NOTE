CLASS zcl_debit_note_preview DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_bgmc_operation .
    INTERFACES if_bgmc_op_single_tx_uncontr .
    INTERFACES if_serializable_object .


    METHODS constructor
      IMPORTING
        iv_bukrs TYPE bukrs
        iv_belnr TYPE belnr_d
        iv_gjahr TYPE gjahr.

  PROTECTED SECTION.
    DATA: im_bukrs TYPE bukrs,
          im_belnr TYPE belnr_d,
          im_gjahr TYPE gjahr.

    METHODS modify
      RAISING
        cx_bgmc_operation.

  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_DEBIT_NOTE_PREVIEW IMPLEMENTATION.


 METHOD constructor .
    im_bukrs = iv_bukrs.
    im_belnr = iv_belnr.
    im_gjahr = iv_gjahr.
  ENDMETHOD.


  METHOD if_bgmc_op_single_tx_uncontr~execute.
    modify( ).
  ENDMETHOD.


   METHOD modify.

    DATA : lwa_data TYPE ztbs_debit_note.
    DATA :lv_pdftest TYPE string.
    DATA lo_pfd TYPE REF TO zcl_debit_note_64.
    CREATE OBJECT lo_pfd.

    lo_pfd->get_pdf_64(
      EXPORTING
        io_bukrs = im_bukrs
        io_belnr = im_belnr
        io_gjahr = im_gjahr
      RECEIVING
        pdf_64     = DATA(pdf_64)
    ).

    lwa_data-bukrs = im_bukrs.
    lwa_data-belnr = im_belnr.
    lwa_data-gjahr = im_gjahr.
    lwa_data-base64 = pdf_64.

    MODIFY ztbs_debit_note FROM @lwa_data.

    CLEAR: lwa_data.
  ENDMETHOD.
ENDCLASS.
