#Include "PROTHEUS.CH"
#Include "FILEIO.CH"

//----------------------------------------------------------------------------//
// Consulta as transacoes via Web Service.
// Para consultar o Web Service de outras maquinas, informe o IP.
//----------------------------------------------------------------------------//
////////////////////////////////////////////////////////////////////////////////
/////////// NAO É NECESSARIO GERAR O WSDL POIS JA ESTA NESTE FONTE /////////////
////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------//
User Function WSTrans()

Local oDlg
Local oBtnOk
Local oFont
Local oTrans, cTrans := ""

Private cServer := Space(30)

Define Font oFont Name "Courier" Size 0,-12            

Define MSDialog oDlg Title "Consulta de Transacoes" From 0,0 To 380,300 Pixel

@010,010 Say "IP do Servidor:" Pixel Of oDlg
@008,047 Get cServer Size 73,10 Picture "@9" Valid If(Empty(cServer), (MsgAlert("Digite um IP"), .F.), .T. ) Pixel Of oDlg

@030,010 Get oTrans Var cTrans Multiline Size 130,150 Pixel Font oFont Of oDlg

@007,122 Button oBtnOk Prompt "&Ok" Size 18,15 Pixel Action Saldo(oTrans, @cTrans) Of oDlg

Activate MSDialog oDlg Centered

Return Nil

//----------------------------------------------------------------------------//
Static Function Saldo(oTrans, cTrans)

Local oWS := WSForneceTrans():New()
Local i

If oWS:BuscaTransacoes()

   cTrans := ""

   For i := 1 To Len(oWS:oWSBuscaTransacoesRESULT:cString)

       If Substr(oWS:oWSBuscaTransacoesRESULT:cString[i], 1, 3) == "SZ1"
          // Dados da conta.
          cTrans += Replicate("-", 29) + Chr(13) + Chr(10)
          cTrans += Substr(oWS:oWSBuscaTransacoesRESULT:cString[i], 4, 20) + Chr(13) + Chr(10)

        Else
          // Dados das transacoes.
          cTrans += Substr(oWS:oWSBuscaTransacoesRESULT:cString[i], 4, 8) + "   " + ;
                    Substr(oWS:oWSBuscaTransacoesRESULT:cString[i],12, 1) + "   " + ;
                    Substr(oWS:oWSBuscaTransacoesRESULT:cString[i],13,14) + Chr(13) + Chr(10)

       EndIf

   Next

 Else

   MsgStop("WSForneceTrans: Web Service nao acessivel!")

EndIf

oTrans:SetText(cTrans)
oTrans:Refresh()

Return .T.

//----------------------------------------------------------------------------//
// WSDL
//----------------------------------------------------------------------------//
#INCLUDE "APWEBSRV.CH"

WSCLIENT WSForneceTrans

	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD RESET
	WSMETHOD CLONE
	WSMETHOD BUSCASALDO
	WSMETHOD BUSCATRANSACOES

	WSDATA   _URL                      AS String
	WSDATA   cNOME                     AS string
	WSDATA   nBUSCASALDORESULT         AS float
	WSDATA   oWSBUSCATRANSACOESRESULT  AS FORNECETRANSACOES_ARRAYOFSTRING

ENDWSCLIENT

WSMETHOD NEW WSCLIENT WSForneceTrans
::Init()
If !FindFunction("XMLCHILDEX")
	UserException("O Código-Fonte Client atual requer os executáveis do Protheus Build [7.00.050721P] ou superior. Atualize o Protheus ou gere o Código-Fonte novamente utilizando o Build atual.")
EndIf
Return Self

WSMETHOD INIT WSCLIENT WSForneceTrans
	::oWSBUSCATRANSACOESRESULT := FORNECETRANSACOES_ARRAYOFSTRING():New()
Return

WSMETHOD RESET WSCLIENT WSForneceTrans
	::cNOME              := NIL 
	::nBUSCASALDORESULT  := NIL 
	::oWSBUSCATRANSACOESRESULT := NIL 
	::Init()
Return

WSMETHOD CLONE WSCLIENT WSForneceTrans
Local oClone := WSForneceTrans():New()
	oClone:_URL          := ::_URL 
	oClone:cNOME         := ::cNOME
	oClone:nBUSCASALDORESULT := ::nBUSCASALDORESULT
	oClone:oWSBUSCATRANSACOESRESULT :=  IIF(::oWSBUSCATRANSACOESRESULT = NIL , NIL ,::oWSBUSCATRANSACOESRESULT:Clone() )
Return oClone

/* -------------------------------------------------------------------------------
WSDL Method BUSCASALDO of Service WSForneceTrans
------------------------------------------------------------------------------- */

WSMETHOD BUSCASALDO WSSEND cNOME WSRECEIVE nBUSCASALDORESULT WSCLIENT WSForneceTrans
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<BUSCASALDO xmlns="http://' + AllTrim(cServer) + '/">'
cSoap += WSSoapValue("NOME", ::cNOME, cNOME , "string", .T. , .F., 0 ) 
cSoap += "</BUSCASALDO>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"http://" + AllTrim(cServer) + "/BUSCASALDO",; 
	"DOCUMENT","http://" + AllTrim(cServer) + "/",,"1.031217",; 
	"http://" + AllTrim(cServer) + "/ws/9901/FORNECESALDO.apw")

::Init()
::nBUSCASALDORESULT  :=  WSAdvValue( oXmlRet,"_BUSCASALDORESPONSE:_BUSCASALDORESULT:TEXT","float",NIL,NIL,NIL,NIL,NIL) 

END WSMETHOD

oXmlRet := NIL
Return .T.

/* -------------------------------------------------------------------------------
WSDL Method BUSCATRANSACOES of Service WSForneceTrans
------------------------------------------------------------------------------- */

WSMETHOD BUSCATRANSACOES WSSEND NULLPARAM WSRECEIVE oWSBUSCATRANSACOESRESULT WSCLIENT WSForneceTrans
Local cSoap := "" , oXmlRet

BEGIN WSMETHOD

cSoap += '<BUSCATRANSACOES xmlns="http://' + AllTrim(cServer) + '/">'
cSoap += "</BUSCATRANSACOES>"

oXmlRet := SvcSoapCall(	Self,cSoap,; 
	"http://" + AllTrim(cServer) + "/BUSCATRANSACOES",; 
	"DOCUMENT","http://" + AllTrim(cServer) + "/",,"1.031217",; 
	"http://" + AllTrim(cServer) + "/ws/9901/FORNECESALDO.apw")

::Init()
::oWSBUSCATRANSACOESRESULT:SoapRecv( WSAdvValue( oXmlRet,"_BUSCATRANSACOESRESPONSE:_BUSCATRANSACOESRESULT","ARRAYOFSTRING",NIL,NIL,NIL,NIL,NIL) )

END WSMETHOD

oXmlRet := NIL
Return .T.


/* -------------------------------------------------------------------------------
WSDL Data Structure ARRAYOFSTRING
------------------------------------------------------------------------------- */

WSSTRUCT FORNECETRANSACOES_ARRAYOFSTRING
	WSDATA   cSTRING                   AS string OPTIONAL
	WSMETHOD NEW
	WSMETHOD INIT
	WSMETHOD CLONE
	WSMETHOD SOAPRECV
ENDWSSTRUCT

WSMETHOD NEW WSCLIENT FORNECETRANSACOES_ARRAYOFSTRING
	::Init()
Return Self

WSMETHOD INIT WSCLIENT FORNECETRANSACOES_ARRAYOFSTRING
	::cSTRING              := {} // Array Of  ""
Return

WSMETHOD CLONE WSCLIENT FORNECETRANSACOES_ARRAYOFSTRING
	Local oClone := FORNECETRANSACOES_ARRAYOFSTRING():NEW()
	oClone:cSTRING              := IIf(::cSTRING <> NIL , aClone(::cSTRING) , NIL )
Return oClone

WSMETHOD SOAPRECV WSSEND oResponse WSCLIENT FORNECETRANSACOES_ARRAYOFSTRING
	Local oNodes1 :=  WSAdvValue( oResponse,"_STRING","string",{},NIL,.T.,"S",NIL) 
	::Init()
	If oResponse = NIL ; Return ; Endif 
	aEval(oNodes1 , { |x| aadd(::cSTRING ,  x:TEXT  ) } )
Return
