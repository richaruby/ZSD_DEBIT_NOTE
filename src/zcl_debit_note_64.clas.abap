CLASS zcl_debit_note_64 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS get_pdf_64
      IMPORTING
                VALUE(io_bukrs) TYPE bukrs
                VALUE(io_belnr) TYPE belnr_d
                VALUE(io_gjahr) TYPE gjahr
      RETURNING VALUE(pdf_64)   TYPE string.

    DATA : lv_item   TYPE string,
           lv_header TYPE string,
           lv_footer TYPE string,
           lv_xml    TYPE string.

    TYPES : BEGIN OF ty_header,
            comp_nm(50) TYPE c,
            state(20) type c,
            state_cd(10) TYPE c,
            gstin(10) TYPE c,
            belnr(10) TYPE c,
            date(10) TYPE c,
            cust_nm(10) TYPE c,
            cust_addrs(500) TYPE c,
            cust_pan(20) TYPE c,
            end of ty_header.

    DATA : gs_header TYPE ty_header.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_DEBIT_NOTE_64 IMPLEMENTATION.


  METHOD get_pdf_64.

    SELECT SINGLE * from i_companycode WHERE CompanyCode = @io_bukrs into @data(wa_comp).

    SELECT SINGLE * FROM i_address_2
    WITH PRIVILEGED ACCESS
    WHERE addressid = @wa_comp-AddressID INTO @DATA(wa_addrs).

      SELECT SINGLE * FROM i_countrytext
        WHERE country = @wa_addrs-country
        AND language = @sy-langu
        INTO @DATA(wa_country_cust).

      SELECT SINGLE * FROM i_regiontext
         WHERE country = @wa_addrs-country
         AND region = @wa_addrs-region
         AND language = @sy-langu
         INTO  @DATA(wa_region_cust).

         if sy-subrc = 0.
            gs_header-state =  wa_region_cust-RegionName .
          gs_header-state_cd =  wa_region_cust-Region .
         ENDIF.


    DATA(lv_addrs) = |{ wa_addrs-Street }, { wa_addrs-CityName }, { wa_addrs-PostalCode }, { wa_addrs-Country }|.

    DATA(lv_state_nm) = wa_addrs-Region.


*          gs_header-gstin  =  wa_cust_soldto-TaxNumber3 .

    SELECT SINGLE * FROM I_JournalEntry
     WHERE AccountingDocument = @io_belnr
      and CompanyCode = @io_bukrs
     AND  FiscalYear = @io_gjahr
     INTO @DATA(wa_journal).
    if sy-subrc = 0.
    gs_header-belnr = wa_journal-AccountingDocument.
    gs_header-date = |{ wa_journal-DocumentDate+6(2) }/{ wa_journal-DocumentDate+4(2) }/{ wa_journal-DocumentDate+0(4) }|.

    SELECT * FROM I_JournalEntryItem
    WHERE AccountingDocument = @io_belnr
    and FiscalYear = @io_gjahr
    and CompanyCode = @io_bukrs
    into TABLE @DATA(it_journalitem).

    ENDIF.



      SELECT * FROM i_billingdocumentpartnerbasic
                WHERE BillingDocument = @io_belnr
                INTO TABLE @DATA(it_vbpa).

    if sy-subrc = 0.
      SELECT * FROM i_customer
      FOR ALL ENTRIES IN @it_vbpa
      WHERE customer = @it_vbpa-Customer
      INTO TABLE @DATA(it_customer).

      if sy-subrc = 0.

       SELECT * FROM I_Address_2
       WITH PRIVILEGED ACCESS
       FOR ALL ENTRIES IN @it_customer
       WHERE addressid = @it_customer-AddressID
       INTO TABLE @DATA(it_cust_addr).

      ENDIF.

    ENDIF.

    READ TABLE it_vbpa INTO DATA(wa_vbpa) INDEX 1.
    READ TABLE it_customer into DATA(wa_customer) WITH KEY Customer = wa_vbpa-Customer.
    if sy-subrc = 0.
    gs_header-cust_nm = wa_customer-CustomerName.

     cl_address_format=>get_instance( )->printform_postal_addr(
                EXPORTING
*                iv_address_type              = '1'
*              iv_address_number            = wa_kna1-addressid
                    iv_address_number            = wa_customer-addressid
*                iv_person_number             =
                  iv_language_of_country_field = sy-langu
*                iv_number_of_lines           = 99
*                iv_sender_country            = space
                IMPORTING
                  ev_formatted_to_one_line     = DATA(one_plant)
                  et_formatted_all_lines       = DATA(all_lines)
              ).

          LOOP AT all_lines INTO DATA(ls_all_lines).
            gs_header-cust_addrs = |{ gs_header-cust_addrs } { ls_all_lines } |.
          ENDLOOP.

            SELECT SINGLE BPIdentificationNumber FROM  I_BuPaIdentification WHERE BusinessPartner =  @wa_customer-Customer
        AND BPIdentificationType = 'PAN' INTO @gs_header-cust_pan .

    ENDIF.




    lv_header = |<form1>| &&
  |<Header>| &&
  |<Header>{ wa_comp-CompanyCodeName }</Header>| &&
  |<header_add>{ lv_addrs }</header_add>| &&
  |<no>{ gs_header-belnr }</no>| &&
  |<ref>{ 1 }</ref>| &&
  |<date>{ gs_header-date }</date>| &&
  |<party_nm>{ gs_header-cust_nm }</party_nm>| &&
  |<party_addrs>{ gs_header-cust_addrs }</party_addrs>| &&
  |<pan_no>{ gs_header-cust_pan }</pan_no>| &&
  |<state_nm>{ 1 }</state_nm>| &&
  |<place>{ 1 }</place>| &&
  |</Header>| &&
  |<Subform1>| &&
  |<table>| &&
  |<Table1>| &&
  |<HeaderRow/>|.

    LOOP AT it_journalitem INTO DATA(wa_journalitem).

    lv_item = lv_item && |<Row1>| &&
              |<particular>{ wa_journalitem-DocumentItemText }</particular>| &&
              |<amount>{ wa_journalitem-AmountInCompanyCodeCurrency }</amount>| &&
              |</Row1>|.

    ENDLOOP.

     lv_footer = |<FooterRow>| &&
                |<on_acc>{ wa_journalitem-DocumentItemText }</on_acc>| &&
                |<amt_in_wrds>{ 1 }</amt_in_wrds>| &&
                |</FooterRow>| &&
                |</Table1>| &&
                |</table>| &&
                |<comp_pan>{ 1 }</comp_pan>| &&
                |<foter_comp_nm>{ wa_comp-CompanyCodeName }</foter_comp_nm>| &&
                |</Subform1>| &&
                |</form1>|.


     lv_xml = |{ lv_header }{ lv_item }{ lv_footer }|.


    CALL METHOD zadobe_call=>getpdf
      EXPORTING
        template = 'ZDEBIT_NOTE/ZDEBIT_NOTE_TEMP'
        xmldata  = lv_xml
      RECEIVING
        result   = DATA(lv_result).

    IF lv_result IS NOT INITIAL.

      pdf_64 = lv_result.

    ENDIF.
  ENDMETHOD.
ENDCLASS.
