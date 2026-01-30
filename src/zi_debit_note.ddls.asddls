@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for Debit Note Adobe Form'
//@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_DEBIT_NOTE
  as select from    I_JournalEntry  as A
    left outer join ztbs_debit_note as b on  A.CompanyCode        = b.bukrs
                                         and A.FiscalYear         = b.gjahr
                                         and A.AccountingDocument = b.belnr
{

  key A.CompanyCode        as BUKRS,
  key A.FiscalYear         as GJAHR,
  key A.AccountingDocument as BELNR,
      b.base64             

}
