#Include "PROTHEUS.CH"
#Include "FILEIO.CH"

//----------------------------------------------------------------------------//
// Consulta o saldo via Web Service.
//----------------------------------------------------------------------------//
User Function WSSaldo()

Local oDlg
Local oBtnOk
Local oBtnCancel
Local cNome
Local oSaldo, nSaldo

cNome  := Space(20)
nSaldo := 0
            
Define MSDialog oDlg Title "Consulta de Saldo" From 0,0 To 220,220 Pixel

@010,10 Say "Nome:" Pixel Of oDlg
@008,50 Get cNome Size 50,10 Picture "@!" Pixel Of oDlg

@045,10 Say "Saldo:" Pixel Of oDlg
@043,50 Get oSaldo Var nSaldo Picture "@E 999,999,999.99" Size 50,10 Pixel When .F. Of oDlg

@oDlg:nHeight/2-37,oDlg:nClientWidth/2-77 Button oBtnOk     Prompt "&Ok"       Size 30,13 Pixel Action Saldo(cNome, oSaldo, @nSaldo) Of oDlg
@oDlg:nHeight/2-37,oDlg:nClientWidth/2-42 Button oBtnCancel Prompt "&Cancelar" Size 30,13 Pixel Action oDlg:End() Cancel             Of oDlg

Activate MSDialog oDlg Centered

Return Nil

//----------------------------------------------------------------------------//
Static Function Saldo(cNome, oSaldo, nSaldo)

Local oWS    := WSForneceSaldo():New()
Local nSaldo := 0

If oWS:BuscaSaldo(cNome)
   nSaldo := oWS:nBuscaSaldoRESULT
 Else
   MsgStop("WSForneceSaldo: Web Service nao acessivel!")
EndIf

oSaldo:SetText(nSaldo)
oSaldo:Refresh()

Return .T.
