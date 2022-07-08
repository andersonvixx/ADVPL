/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ PRENOTAº Autor ³ Luiz Alberto º Data ³ 29/10/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Leitura e Importacao Arquivo XML para geração de Pre-Nota  º±±
±±º          ³                                                     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

//-- Ponto de Entrada para incluir botão na Pré-Nota de Entrada

#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#include "RWMAKE.ch"
#include "Colors.ch"
#include "Font.ch"
#Include "HBUTTON.CH"
#include "Topconn.ch"
#INCLUDE "AP5MAIL.CH"

/* ATENCAO PARA QUE A ROTINA FUNCIONE CORRETAMENTE
EXISTE A NECESSIDADE DE CRIAÇÃO DE DOIS INDICES

TABELA SA5
CHAVE: FILIAL + FORNECEDOR + LOJA + CODIGO PRODUTO NO FORNECEDOR

A5_FILIAL + A5_FORNECE + A5_LOJA + A5_CODPRF

NICK NAME - > FORPROD

TABELA SA7
CHAVE: FILIAL + CLIENTE + LOJA + CODIGO PRODUTO CLIENTE

A7_FILIAL + A7_CLIENTE + A7_LOJA + A7_CODCLI

NICK NAME -> CLIPROD

**Cleber Orati** :
  * Caso banco de dados não for compatível excluir cláusula WITH (NOLOCK) da 
  query que consulta pedidos, esta cláusula impede que registros bloqueados (em transaction) bloqueiem a consulta
    

*/
User Function PreNotaXML
Local aTipo			:={'N','B','D'}
Local cArquivo 		:= ""
Local cAuxMail,lBloqueado,nX,nTipo,nIpi,lMarcou,lAchou
Private CPERG   	:="NOTAXML"
Private Caminho 	:= "\SYSTEM\XMLNFE\" //"E:\Protheus10_Teste\protheus_data\XmlNfe\  Foi alterado para \System\XmlNfe\ para funcionar de qualquer estacao Emerson Holanda 10/11/10
Private _cMarca   := GetMark()
Private aFields   := {}
Private cArq,nHdl
Private aFields2  := {}
Private cArq2,cProds,cCodBar
Private oAux,oICM,oNF,oNFChv,oEmitente,oIdent,oDestino,oTotal,oTransp,oDet,cChvNfe  
Private oFatura,cEdit1,_DESCdigit,_NCMdigit,lOut,lOk,_oPT00005
Private lMsErroAuto,lMsHelpAuto
Private lPcNfe		:= GETMV("MV_PCNFE")
PutMV("MV_PCNFE",.f.)


nTipo := 1
lOut := .f. //Sair do programa
Do While .T.
	cCodBar := space(44)
	cArquivo := ""
	_oPT00005 := nil
	DEFINE MSDIALOG _oPT00005 FROM  50, 050 TO 400,500 TITLE OemToAnsi('Busca de XML de Notas Fiscais de Entrada') PIXEL	// "Movimenta‡„o Banc ria"
	
	@ 003,005 Say OemToAnsi("Cod Barra NFE") Size 040,030
	@ 030,005 Say OemToAnsi("Tipo Nota Entrada:") Size 070,030
	
	@ 003,060 Get cCodBar  Picture "@!S80" Valid AchaFile(@cArquivo)  Size 150,030
	@ 020,060 RADIO oTipo VAR nTipo ITEMS "Nota Normal","Nota Beneficiamento","Nota Devolução" SIZE 70,10 OF _oPT00005
	
	
	@ 135,060 Button OemToAnsi("Arquivo") Size 036,016 Action (GetArq(@cArquivo),_oPT00005:End())
	@ 135,110 Button OemToAnsi("Ok")  Size 036,016 Action (_oPT00005:End())
	@ 135,160 Button OemToAnsi("Sair")   Size 036,016 Action Fecha()
	
	Activate Dialog _oPT00005 CENTERED
	
	if lOut
		exit
	endif 
	MV_PAR01 := nTipo
	
	//cArquivo := cCodBar
	
	If empty(cArquivo) .or. (!Empty(cArquivo) .and. !File(cArquivo))
		MsgAlert("Arquivo Não Encontrado no Local de Origem Indicado!")
//		PutMV("MV_PCNFE",lPcNfe)                                       
		if type("_oPT00005") <> "U"
			_oPT00005:End()
			Close(_oPT00005)
		endif 
		loop 
	Endif
	
	cCodBar := alltrim(cCodBar)
	nHdl    := fOpen(cArquivo,0)
	
	
	aCamposPE:={}
	
	If nHdl == -1
		If !Empty(cArquivo)
			MsgAlert("O arquivo de nome "+cArquivo+" nao pode ser aberto! Verifique os parametros.","Atencao!")
		Endif
		PutMV("MV_PCNFE",lPcNfe)
		Return
	Endif
	nTamFile := fSeek(nHdl,0,2)
	fSeek(nHdl,0,0)
	cBuffer  := Space(nTamFile)                // Variavel para criacao da linha do registro para leitura
	nBtLidos := fRead(nHdl,@cBuffer,nTamFile)  // Leitura  do arquivo XML
	fClose(nHdl)
	
	cAviso := ""
	cErro  := ""
	oNfe := XmlParser(cBuffer,"_",@cAviso,@cErro)
	
	If Type("oNFe:_NfeProc")<> "U"
		oNF := oNFe:_NFeProc:_NFe
	Else   
		if Type("oNFe:_NFe") <> "U"
			oNF := oNFe:_NFe
		ELSE  
			MsgAlert("Não foi possível abrir o arquivo XML, provavel falha em sua estrutura. Por favor substitua o arquivo","Atencao!")
		ENDIF 
	Endif
	
	oNFChv := oNFe:_NFeProc:_protNFe
	
	oEmitente  := oNF:_InfNfe:_Emit
	oIdent     := oNF:_InfNfe:_IDE
	oDestino   := oNF:_InfNfe:_Dest
	oTotal     := oNF:_InfNfe:_Total
	oTransp    := oNF:_InfNfe:_Transp
	oDet       := oNF:_InfNfe:_Det
	cChvNfe    := oNFChv:_INFPROT:_CHNFE:TEXT
	
	//	<chNFe>41101108365527000121550050000014611623309134</chNFe>
	If Type("oNF:_InfNfe:_ICMS")<> "U"
		oICM := oNF:_InfNfe:_ICMS
	Else
		oICM := nil
	Endif 
	
	oFatura    := IIf(Type("oNF:_InfNfe:_Cobr")=="U",Nil,oNF:_InfNfe:_Cobr)
	cEdit1	   := Space(15)
	_DESCdigit :=space(55)
	_NCMdigit  :=space(8)
	
	
	oDet := IIf(ValType(oDet)=="O",{oDet},oDet)
	// Validações -------------------------------
	// -- CNPJ da NOTA = CNPJ do CLIENTE ? oEmitente:_CNPJ
	If MV_PAR01 = 1
		cTipo := "N"
	ElseIF MV_PAR01 = 2
		cTipo := "B"
	ElseIF MV_PAR01 = 3
		cTipo := "D"
	Endif
	
	
	// CNPJ ou CPF
	
	cCgc := AllTrim(IIf(Type("oDestino:_CPF")=="U",oDestino:_CNPJ:TEXT,oDestino:_CPF:TEXT)) 
	if !(cCgc == alltrim(SM0->M0_CGC))
		//Tratamento Brasilux Depósito Fechado. Possibilidade de entrada em notas para armazenagem
		if !(alltrim(SM0->M0_CGC) == "72770878000540")
			MsgAlert("Nota Fiscal pertencente a OUTRA EMPRESA ou FILIAL. Por favor efetuar login no seguinte CNPJ: " + cCgc)
			loop 
		endif 
	Endif
		

	cCgc := AllTrim(IIf(Type("oEmitente:_CPF")=="U",oEmitente:_CNPJ:TEXT,oEmitente:_CPF:TEXT))
	

	lAchou := .f.                                   
	// Considerar situação em que registro está bloqueado
	If MV_PAR01 = 1 // Nota Normal Fornecedor                     
		dbselectarea("SA2")
		dbSetOrder(3)
		dbSeek(xFilial("SA2")+cCgc)
		do while !lAchou .and. !eof() .and. (xFilial("SA2") = SA2->A2_FILIAL) .AND. (TRIM(SA2->A2_CGC) == cCgc)
			IF FieldPos("A2_MSBLQL") > 0
				IF !(SA2->A2_MSBLQL == "1")
					lAchou := .t.          
					EXIT
				endif
			else
				lAchou := .t.  
				EXIT 
			endif
			dbselectarea('SA2')
			dbskip()
		enddo 
	Else
		dbselectarea("SA1")
		dbSetOrder(3)
		dbSeek(xFilial("SA1")+cCgc)
		do while !lAchou .and. !eof() .and. (xFilial("SA1") = SA1->A1_FILIAL) .AND. (TRIM(SA1->A1_CGC) == cCgc)
			IF FieldPos("A1_MSBLQL") > 0
				IF !(SA1->A1_MSBLQL == "1")
					lAchou := .t.
					EXIT 
				endif
			else
				lAchou := .t.    
				EXIT 
			endif
			dbselectarea('SA1')
			dbskip()
		enddo 
	Endif
	If !lAchou
		MsgAlert("CNPJ Origem Não Localizado - Verifique " + cCgc)
		PutMV("MV_PCNFE",lPcNfe)
		Return
	Endif
	
	// -- Nota Fiscal já existe na base ?
	If SF1->(DbSeek(XFilial("SF1")+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+Padr(OIdent:_serie:TEXT,3)+SA2->A2_COD+SA2->A2_LOJA))
		IF MV_PAR01 = 1
			MsgAlert("Nota No.: "+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+"/"+OIdent:_serie:TEXT+" do Fornec. "+SA2->A2_COD+"/"+SA2->A2_LOJA+" Ja Existe. A Importacao sera interrompida")
		Else
			MsgAlert("Nota No.: "+Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)+"/"+OIdent:_serie:TEXT+" do Cliente "+SA1->A1_COD+"/"+SA1->A1_LOJA+" Ja Existe. A Importacao sera interrompida")
		Endif
		PutMV("MV_PCNFE",lPcNfe)
		Return Nil
	EndIf
	
	aCabec := {}
	aItens := {}
	aadd(aCabec,{"F1_TIPO"   ,If(MV_PAR01==1,"N",If(MV_PAR01==2,'B','D')),Nil,Nil})
	aadd(aCabec,{"F1_FORMUL" ,"N",Nil,Nil})
	aadd(aCabec,{"F1_DOC"    ,Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9),Nil,Nil})
	//If OIdent:_serie:TEXT ='0'
	//	aadd(aCabec,{"F1_SERIE"  ,"   ",Nil,Nil})
	//Else
	aadd(aCabec,{"F1_SERIE"  ,OIdent:_serie:TEXT,Nil,Nil})
	//Endif
	
	
	cData:=Alltrim(OIdent:_dEmi:TEXT)
	dData:=CTOD(Right(cData,2)+'/'+Substr(cData,6,2)+'/'+Left(cData,4))
	aadd(aCabec,{"F1_EMISSAO",dData,Nil,Nil})
	aadd(aCabec,{"F1_FORNECE",If(MV_PAR01=1,SA2->A2_COD,SA1->A1_COD),Nil,Nil})
	aadd(aCabec,{"F1_LOJA"   ,If(MV_PAR01=1,SA2->A2_LOJA,SA1->A1_LOJA),Nil,Nil})
	aadd(aCabec,{"F1_ESPECIE","SPED ",Nil,Nil})
	aadd(aCabec,{"F1_CHVNFE",cChvNfe,Nil,Nil})
	
	//If cTipo == "N"
	//	aadd(aCabec,{"F1_COND" ,If(Empty(SA2->A2_COND),'007',SA2->A2_COND),Nil,Nil})
	//Else
	//	aadd(aCabec,{"F1_COND" ,If(Empty(SA1->A1_COND),'007',SA1->A1_COND),Nil,Nil})
	//Endif
	
	
	// Primeiro Processamento
	// Busca de Informações para Pedidos de Compras
	
	cProds := ''
	aPedIte:={}
	
	For nX := 1 To Len(oDet)
		cEdit1 := Space(15)
		_DESCdigit :=space(55)
		_NCMdigit  :=space(8)
		
		If MV_PAR01 = 1
			cProduto:=PadR(AllTrim(oDet[nX]:_Prod:_cProd:TEXT),TamSx3("A5_CODPRF")[1])
			xProduto:=cProduto
			
			oAux := oDet[nX]
			cNCM:=IIF(Type("oAux:_Prod:_NCM")=="U",space(12),oAux:_Prod:_NCM:TEXT)
			Chkproc=.F.
			
			SA5->(DbOrderNickName("FORPROD"))   // FILIAL + FORNECEDOR + LOJA + CODIGO PRODUTO NO FORNECEDOR
			If !SA5->(dbSeek(xFilial("SA5")+SA2->A2_COD+SA2->A2_LOJA+cProduto))
				If !MsgYesNo ("Produto Cod.: "+cProduto+" Nao Encontrado. Digita Codigo de Substituicao?")
					PutMV("MV_PCNFE",lPcNfe)
					Return Nil
				Endif
				DEFINE MSDIALOG _oDlg TITLE "Dig.Cod.Substituicao" FROM C(177),C(192) TO C(509),C(659) PIXEL
				
				// Cria as Groups do Sistema
				@ C(002),C(003) TO C(071),C(186) LABEL "Dig.Cod.Substituicao " PIXEL OF _oDlg
				
				// Cria Componentes Padroes do Sistema
				@ C(012),C(027) Say "Produto: "+cProduto+" - NCM: "+cNCM Size C(150),C(008) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(020),C(027) Say "Descricao: "+oDet[nX]:_Prod:_xProd:TEXT Size C(150),C(008) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(028),C(070) MsGet oEdit1 Var cEdit1 F3 "SB1" Valid(ValProd()) Size C(060),C(009) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(040),C(027) Say "Produto digitado: "+cEdit1+" - NCM: "+_NCMdigit Size C(150),C(008) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(048),C(027) Say "Descricao: "+_DESCdigit Size C(150),C(008) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(004),C(194) Button "Processar" Size C(037),C(012) PIXEL OF _oDlg Action(Troca())
				@ C(025),C(194) Button "Cancelar" Size C(037),C(012) PIXEL OF _oDlg Action(_oDlg:End())
				oEdit1:SetFocus()
				
				ACTIVATE MSDIALOG _oDlg CENTERED
				If Chkproc!=.T.
					MsgAlert("Produto Cod.: "+cProduto+" Nao Encontrado. A Importacao sera interrompida")
					PutMV("MV_PCNFE",lPcNfe)
					Return Nil
				Else
					If SA5->(dbSetOrder(1), dbSeek(xFilial("SA5")+SA2->A2_COD+SA2->A2_LOJA+cEdit1))
						RecLock("SA5",.f.)
					Else
						Reclock("SA5",.t.)
					Endif
					
					SA5->A5_FILIAL := xFilial("SA5")
					SA5->A5_FORNECE := SA2->A2_COD
					SA5->A5_LOJA 	:= SA2->A2_LOJA
					SA5->A5_NOMEFOR := SA2->A2_NOME
					SA5->A5_PRODUTO := cEdit1 //SB1->B1_COD
					SA5->A5_NOMPROD := oDet[nX]:_Prod:_xProd:TEXT
					//			 		SA5->A5_PRODDES :=
					SA5->A5_CODPRF  := xProduto 
					IF EMPTY(SA5->A5_SITU)  
						SA5->A5_SITU := "C"
					ENDIF
					IF SA5->A5_TEMPLIM = 0.0
						SA5->A5_TEMPLIM :=  1
					ENDIF 
					IF EMPTY(SA5->A5_FABREV)
						SA5->A5_FABREV := "F"					
					ENDIF 
					SA5->(MsUnlock())
				EndIf
			endif 
			SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+SA5->A5_PRODUTO))
				
			If !Empty(cNCM) .and. cNCM != '00000000' .And. empty(SB1->B1_POSIPI) //SB1->B1_POSIPI <> cNCM 
				dbselectarea("SYD")
				dbsetorder(1)
				dbseek(xFilial("SYD")+PADR(cNCM,TamSx3("YD_TEC")[1])+SB1->B1_EX_NCM+B1_EX_NBM)
				nIpi := iif(found(),SYD->YD_PER_IPI,0)
				dbselectarea("SB1")
				RecLock("SB1",.F.)
				Replace B1_POSIPI with cNCM
				replace B1_IPI with nIpi
				MSUnLock()
			Endif
		Else
			
			cProduto:=PadR(AllTrim(oDet[nX]:_Prod:_cProd:TEXT),TamSx3("A7_CODCLI")[1])
			xProduto:=cProduto
			oAux := oDet[nX]			
			cNCM:=IIF(Type("oAux:_Prod:_NCM")=="U",space(12),oAux:_Prod:_NCM:TEXT)
			Chkproc=.F.
			
			SA7->(DbOrderNickName("CLIPROD"))   // FILIAL + FORNECEDOR + LOJA + CODIGO PRODUTO NO FORNECEDOR
			
			If !SA7->(dbSeek(xFilial("SA7")+SA1->A1_COD+SA1->A1_LOJA+cProduto))
				If !MsgYesNo ("Produto Cod.: "+cProduto+" Nao Encontrado. Digita Codigo de Substituicao?")
					PutMV("MV_PCNFE",lPcNfe)
					Return Nil
				Endif
				DEFINE MSDIALOG _oDlg TITLE "Dig.Cod.Substituicao" FROM C(177),C(192) TO C(509),C(659) PIXEL
				
				// Cria as Groups do Sistema
				@ C(002),C(003) TO C(071),C(186) LABEL "Dig.Cod.Substituicao " PIXEL OF _oDlg
				
				// Cria Componentes Padroes do Sistema
				@ C(012),C(027) Say "Produto: "+cProduto+" - NCM: "+cNCM Size C(150),C(008) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(020),C(027) Say "Descricao: "+oDet[nX]:_Prod:_xProd:TEXT Size C(150),C(008) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(028),C(070) MsGet oEdit1 Var cEdit1 F3 "SB1" Valid(ValProd()) Size C(060),C(009) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(040),C(027) Say "Produto digitado: "+cEdit1+" - NCM: "+_NCMdigit Size C(150),C(008) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(048),C(027) Say "Descricao: "+_DESCdigit Size C(150),C(008) COLOR CLR_HBLUE PIXEL OF _oDlg
				@ C(004),C(194) Button "Processar" Size C(037),C(012) PIXEL OF _oDlg Action(Troca())
				@ C(025),C(194) Button "Cancelar" Size C(037),C(012) PIXEL OF _oDlg Action(_oDlg:End())
				oEdit1:SetFocus()
				
				ACTIVATE MSDIALOG _oDlg CENTERED
				If Chkproc!=.T.
					MsgAlert("Produto Cod.: "+cProduto+" Nao Encontrado. A Importacao sera interrompida")
					PutMV("MV_PCNFE",lPcNfe)
					Return Nil
				Else
					If SA7->(dbSetOrder(1), dbSeek(xFilial("SA7")+SA1->A1_COD+SA1->A1_LOJA+cEdit1))
						RecLock("SA7",.f.)
					Else
						Reclock("SA7",.t.)
					Endif
					
					SA7->A7_FILIAL := xFilial("SA7")
					SA7->A7_CLIENTE := SA1->A1_COD
					SA7->A7_LOJA 	:= SA1->A1_LOJA
					SA7->A7_DESCCLI := oDet[nX]:_Prod:_xProd:TEXT
					SA7->A7_PRODUTO := cEdit1 //SB1->B1_COD
					SA7->A7_CODCLI  := xProduto
					SA7->(MsUnlock())
					
				EndIf
			endif 
			SB1->(dbSetOrder(1), dbSeek(xFilial("SB1")+SA7->A7_PRODUTO))
			If !Empty(cNCM) .and. cNCM != '00000000' .And. empty(SB1->B1_POSIPI) //SB1->B1_POSIPI <> cNCM
				dbselectarea("SYD")
				dbsetorder(1)
				dbseek(xFilial("SYD")+PADR(cNCM,TamSx3("YD_TEC")[1])+SB1->B1_EX_NCM+B1_EX_NBM)
				nIpi := iif(found(),SYD->YD_PER_IPI,0)
				dbselectarea("SB1")
				RecLock("SB1",.F.)
				Replace B1_POSIPI with cNCM
				replace B1_IPI with nIpi
				MSUnLock()

			Endif
		Endif
		SB1->(dbSetOrder(1))
		
		cProds += ALLTRIM(SB1->B1_COD)+'/'
		
		AAdd(aPedIte,{SB1->B1_COD,Val(oDet[nX]:_Prod:_qTrib:TEXT),Round(Val(oDet[nX]:_Prod:_vProd:TEXT)/Val(oDet[nX]:_Prod:_qCom:TEXT),6),Val(oDet[nX]:_Prod:_vProd:TEXT)})
		
	Next nX
	
	// Retira a Ultima "/" da Variavel cProds
	
	cProds := Left(cProds,Len(cProds)-1)
	
	aCampos := {}
	aCampos2:= {}
	
	AADD(aCampos,{'T9_OK'			,'#','@!','2','0'})
	AADD(aCampos,{'T9_PEDIDO'		,'Pedido','@!','6','0'})
	AADD(aCampos,{'T9_ITEM'			,'Item','@!','3','0'})
	AADD(aCampos,{'T9_PRODUTO'		,'PRODUTO','@!','15','0'})
	AADD(aCampos,{'T9_DESC'			,'Descrição','@!','40','0'})
	AADD(aCampos,{'T9_UM'			,'Un','@!','02','0'})
	AADD(aCampos,{'T9_QTDE'			,'Qtde','@EZ 999,999.9999','10','4'})
	AADD(aCampos,{'T9_UNIT'			,'Unitario','@EZ 9,999,999.99','12','2'})
	AADD(aCampos,{'T9_TOTAL'		,'Total','@EZ 99,999,999.99','14','2'})
	AADD(aCampos,{'T9_DTPRV'		,'Dt.Prev','','10','0'})
	AADD(aCampos,{'T9_ALMOX'		,'Alm','','2','0'})
	AADD(aCampos,{'T9_OBSERV'		,'Observação','@!','30','0'})
	AADD(aCampos,{'T9_CCUSTO'		,'C.Custo','@!','6','0'})
	AADD(aCampos,{'T9_TES'			,'TES','999','3','0'})
	
	AADD(aCampos2,{'T8_NOTA'			,'N.Fiscal','@!','9','0'})
	AADD(aCampos2,{'T8_SERIE'		,'Serie','@!','3','0'})
	AADD(aCampos2,{'T8_PRODUTO'		,'PRODUTO','@!','15','0'})
	AADD(aCampos2,{'T8_DESC'			,'Descrição','@!','40','0'})
	AADD(aCampos2,{'T8_UM'			,'Un','@!','02','0'})
	AADD(aCampos2,{'T8_QTDE'			,'Qtde','@EZ 999,999.9999','10','4'})
	AADD(aCampos2,{'T8_UNIT'			,'Unitario','@EZ 9,999,999.99','12','2'})
	AADD(aCampos2,{'T8_TOTAL'		,'Total','@EZ 99,999,999.99','14','2'})
	
	Cria_TC9()
	
	For ni := 1 To Len(aPedIte)
		RecLock("TC8",.t.)
		TC8->T8_NOTA 	:= Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)
		TC8->T8_SERIE 	:= OIdent:_serie:TEXT
		TC8->T8_PRODUTO := aPedIte[nI,1]
		TC8->T8_DESC	:= Posicione("SB1",1,xFilial("SB1")+aPedIte[nI,1],"B1_DESC")
		TC8->T8_UM		:= SB1->B1_UM
		TC8->T8_QTDE	:= aPedIte[nI,2]
		TC8->T8_UNIT	:= aPedIte[nI,3]
		TC8->T8_TOTAL	:= aPedIte[nI,4]
		TC8->(msUnlock())
	Next
	TC8->(dbGoTop())
	
	Monta_TC9()
	
	lOk := .f.
	lOut := .f.	//POLIESTER
	If !Empty(TC9->(RecCount()))
		
		
		DbSelectArea('TC9')
		@ 100,005 TO 500,750 DIALOG oDlgPedidos TITLE "Pedidos de Compras Associados ao XML selecionado!"	//Poliester
		
		
		@ 006,005 TO 100,325 BROWSE "TC9" MARK "T9_OK" FIELDS aCampos Object _oBrwPed
		
		@ 066,330 BUTTON "Marcar"         SIZE 40,15 ACTION MsAguarde({||MarcarTudo()},'Marcando Registros...')
		@ 086,330 BUTTON "Desmarcar"      SIZE 40,15 ACTION MsAguarde({||DesMarcaTudo()},'Desmarcando Registros...')
		@ 106,330 BUTTON "Processar"	  SIZE 40,15 ACTION MsAguarde({|| lOk := .t. , Close(oDlgPedidos)},'Gerando e Enviando Arquivo...')
		@ 183,330 BUTTON "Sair"			  SIZE 40,15 ACTION MsAguarde({|| lOut := .t., Close(oDlgPedidos)},'Saindo do Sistema')	//POLIESTER
//		@ 183,330 BUTTON "Sair"           SIZE 40,15 ACTION Close(oDlgPedidos)
		
//		Processa({||  } ,"Selecionando Informacoes de Pedidos de Compras...")
		
		DbSelectArea('TC8')
		
		@ 100,005 TO 190,325 BROWSE "TC8" FIELDS aCampos2 Object _oBrwPed2
		
		DbSelectArea('TC9')
		
		_oBrwPed:bMark := {|| Marcar()}
		
		ACTIVATE DIALOG oDlgPedidos CENTERED
		
	Endif

//Verifica se o usuário clicou no botão para sair, anteriormente se ele clicasse para sair o sistema ainda fazia a inserçao dos dados, agora não. - Poliester
	If lOut
		Return
	Endif
	
	
	// Verifica se o usuario selecionou algum pedido de compra
	
	dbSelectArea("TC9")
	dbGoTop()
	ProcRegua(Reccount())
	
	lMarcou := .f.
	
	While !Eof() .And. lOk
		IncProc()
		If TC9->T9_OK  <> _cMarca
			dbSelectArea("TC9")
			TC9->(dbSkip(1));Loop
		Else
			lMarcou := .t.
			Exit
		Endif
		
		TC9->(dbSkip(1))
	Enddo
	
	
	
	
	For nX := 1 To Len(oDet)
		
		// Validacao: Produto Existe no SB1 ?
		// Se não existir, abrir janela c/ codigo da NF e descricao para digitacao do cod. substituicao.
		// Deixar opção para cancelar o processamento //  Descricao: oDet[nX]:_Prod:_xProd:TEXT
		
		aLinha := {}
		cProduto:=PADR(AllTrim(oDet[nX]:_Prod:_cProd:TEXT),TamSX3( "A5_CODPRF" )[1])
		xProduto:=cProduto
		
		oAux := oDet[nX]
		cNCM:=IIF(Type("oAux:_Prod:_NCM")=="U",space(12),oAux:_Prod:_NCM:TEXT)
		Chkproc=.F.
		
		If MV_PAR01 == 1
			SA5->(DbOrderNickName("FORPROD"))   // FILIAL + FORNECEDOR + LOJA + CODIGO PRODUTO NO FORNECEDOR
			SA5->(dbSeek(xFilial("SA5")+SA2->A2_COD+SA2->A2_LOJA+cProduto))
			SB1->(dbSetOrder(1) , dbSeek(xFilial("SB1")+SA5->A5_PRODUTO))  
			
		Else
			SA7->(DbOrderNickName("CLIPROD"))
			SA7->(dbSeek(xFilial("SA7")+SA1->A1_COD+SA1->A1_LOJA+cProduto))
			SB1->(dbSetOrder(1) , dbSeek(xFilial("SB1")+SA7->A7_PRODUTO))
		Endif
		
		aadd(aLinha,{"D1_COD",SB1->B1_COD,Nil,Nil}) //Emerson Holanda
		If Val(oDet[nX]:_Prod:_qTrib:TEXT) != 0
			aadd(aLinha,{"D1_QUANT",Val(oDet[nX]:_Prod:_qTrib:TEXT),Nil,Nil})
			aadd(aLinha,{"D1_VUNIT",Round(Val(oDet[nX]:_Prod:_vProd:TEXT)/Val(oDet[nX]:_Prod:_qTrib:TEXT),6),Nil,Nil})
		Else
			aadd(aLinha,{"D1_QUANT",Val(oDet[nX]:_Prod:_qCom:TEXT),Nil,Nil})
			aadd(aLinha,{"D1_VUNIT",Round(Val(oDet[nX]:_Prod:_vProd:TEXT)/Val(oDet[nX]:_Prod:_qCom:TEXT),6),Nil,Nil})
		Endif
		//Val(oDet[nX]:_Prod:_vUnCom:TEXT)
		aadd(aLinha,{"D1_TOTAL",Val(oDet[nX]:_Prod:_vProd:TEXT),Nil,Nil})
		_cfop:=oDet[nX]:_Prod:_CFOP:TEXT
		If Left(Alltrim(_cfop),1)="5"
			_cfop:=Stuff(_cfop,1,1,"1")
		Else
			_cfop:=Stuff(_cfop,1,1,"2")
		Endif
		//	      aadd(aLinha,{"D1_CF",_cfop,Nil,Nil})
		oAux := oDet[nX]
		If Type("oAux:_Prod:_vDesc") <> "U"
            aadd(aLinha,{"D1_VALDESC",Val(oDet[nX]:_Prod:_vDesc:TEXT),Nil,Nil})
        Else 
            aadd(aLinha,{"D1_VALDESC",0,Nil,Nil})            
        Endif
		Do Case
			Case Type("oAux:_Imposto:_ICMS:_ICMS00") <> "U"
				oICM:=oAux:_Imposto:_ICMS:_ICMS00
			Case Type("oAux:_Imposto:_ICMS:_ICMS10") <> "U"
				oICM:=oAux:_Imposto:_ICMS:_ICMS10
			Case Type("oAux:_Imposto:_ICMS:_ICMS20") <> "U"
				oICM:=oAux:_Imposto:_ICMS:_ICMS20
			Case Type("oAux:_Imposto:_ICMS:_ICMS30") <> "U"
				oICM:=oAux:_Imposto:_ICMS:_ICMS30
			Case Type("oAux:_Imposto:_ICMS:_ICMS40") <> "U"
				oICM:=oAux:_Imposto:_ICMS:_ICMS40
			Case Type("oAux:_Imposto:_ICMS:_ICMS51") <> "U"
				oICM:=oAux:_Imposto:_ICMS:_ICMS51
			Case Type("oAux:_Imposto:_ICMS:_ICMS60") <> "U"
				oICM:=oAux:_Imposto:_ICMS:_ICMS60
			Case Type("oAux:_Imposto:_ICMS:_ICMS70") <> "U"
				oICM:=oAux:_Imposto:_ICMS:_ICMS70
			Case Type("oAux:_Imposto:_ICMS:_ICMS90") <> "U"
				oICM:=oAux:_Imposto:_ICMS:_ICMS90
		EndCase
		If (Type("oICM:_orig:TEXT") <> "U") .And. (Type("oICM:_CST:TEXT") <> "U")
			CST_Aux:=Alltrim(oICM:_orig:TEXT)+Alltrim(oICM:_CST:TEXT)
			aadd(aLinha,{"D1_CLASFIS",CST_Aux,Nil,Nil})
		ELSE
			aadd(aLinha,{"D1_CLASFIS",'',Nil,Nil})
		Endif
		
//		If lMarcou

			//Cleber Orati => conocando .F. na terceira coluna faz com que não valide o pedido
			//no caso de se passar pedido em branco.
			aadd(aLinha,{"D1_PEDIDO",'',.f.,Nil})
			aadd(aLinha,{"D1_ITEMPC",'',.f.,Nil})
//		Endif 

		//		If cTipo=='D' // Nota Fiscal de Devolucao
		//			aadd(aLinha,{"D1_NFORI",'',Nil,Nil})
		//			aadd(aLinha,{"D1_ITEMORI",'',Nil,Nil})
		//			aadd(aLinha,{"D1_SERIORI",'',Nil,Nil})
		//		Endif
		
		
		
		aadd(aItens,aLinha)
	Next nX
	
	
	If lMarcou
		
		dbSelectArea("TC9")
		dbGoTop()
		ProcRegua(Reccount())
		
		While !Eof() .And. lOk
			IncProc()
			If TC9->T9_OK  <> _cMarca
				dbSelectArea("TC9")
				TC9->(dbSkip(1));Loop
			Endif
			
			For nItem := 1 To Len(aItens)
				If AllTrim(aItens[nItem,1,2]) == AllTrim(TC9->T9_PRODUTO) .And. Empty(aItens[nItem,7,2])
					If !Empty(TC9->T9_QTDE)
						aItens[nItem,7,2] := TC9->T9_PEDIDO
						aItens[nItem,8,2] := TC9->T9_ITEM 
						dbselectarea("SC7")
						dbsetorder(1)
						
						if (FieldPos("C7_XCST") > 0) .and. !empty(aItens[nItem,6,2])     
							dbselectarea("SC7")
							dbseek(xFilial("SC7")+TC9->T9_PEDIDO+TC9->T9_ITEM)
							if found()
								reclock("SC7",.F.)
								SC7->C7_XCST := aItens[nItem,6,2]
								SC7->(MsUnlock())
							endif   
						endif 
						
						If RecLock('TC9',.f.)
							If (TC9->T9_QTDE-aItens[nItem,2,2]) < 0
								TC9->T9_QTDE := 0
							Else
								TC9->T9_QTDE := (TC9->T9_QTDE - aItens[nItem,2,2])
							Endif
							TC9->(MsUnlock())
						Endif
					Endif
				Endif
			Next
			
			
			TC9->(dbSkip(1))
		Enddo
		
		
		TC8->(dbCloseArea())
		TC9->(dbCloseArea())
	Endif
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//| Teste de Inclusao                                            |
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Len(aItens) > 0 
	
		lMsErroAuto := .f.
		lMsHelpAuto := .f.
		
		SB1->( dbSetOrder(1) )
		SA2->( dbSetOrder(1) )
		
		nModulo := 2  //COMPRAS
		dbselectarea("SD1")
		dbsetorder(1)
		dbselectarea("SF1")
		dbsetorder(1)             
		
		MSExecAuto({|x,y,z|Mata140(x,y,z)},aCabec,aItens,3)
		
		IF lMsErroAuto 
			if ("PROCESSADOS\" $ Upper(cArquivo))
				xFile := STRTRAN(Upper(cArquivo),"XMLNFE\PROCESSADOS\", "XMLNFE\ERRO\")
			ELSE 
				xFile := STRTRAN(Upper(cArquivo),"XMLNFE\", "XMLNFE\ERRO\")
			ENDIF 
			
			COPY FILE &cArquivo TO &xFile
			
			FErase(cArquivo)
			
			MSGALERT("ERRO NO PROCESSO")
			MostraErro()
		Else
			If SF1->F1_DOC == Right("000000000"+Alltrim(OIdent:_nNF:TEXT),9)
				ConfirmSX8()
/*				// Grava Chave da Nota Fiscal Eletronica  
				dbselectarea("SF1")
				lBloqueado := U_EstaBloqueado("SF1",recno())
	  			If !lBloqueado       
	  				RecLock("SF1",.f.)
	  			endif                 
	  			
					SF1->F1_CHVNFE := cChvNfe
	  			If !lBloqueado       
					MsUnlock()
				Endif
*/
			if !("PROCESSADOS\" $ Upper(cArquivo))
				xFile := STRTRAN(Upper(cArquivo),"XMLNFE\", "XMLNFE\PROCESSADOS\")
				
				COPY FILE &cArquivo TO &xFile
				
				FErase(cArquivo)
			endif 
				
				MSGALERT(Alltrim(aCabec[3,2])+' / '+Alltrim(aCabec[4,2])+" - Pré Nota Gerada Com Sucesso!")
				
				
				
				//				If SF1->F1_PLUSER <> __cUserId
				//					If Reclock("SF1",.F.)
				//						SF1->F1_PLUSER := __cUserId
				//					EndIf
				//				EndIf
				//				Desabilitado pois a Solange e Luciene serão as unicas que poderão classificar notas
				/*			IF Msgyesno("Deseja Efetuar a Classificação da Nota " + Alltrim(aCabec[3,2])+' / '+Alltrim(aCabec[4,2]) + " Agora ?")
				_aArea := GetArea()
				//A103NFiscal("SF1",SF1->(Recno()),4,.f.,.f.)
				dbSelectArea("SF1")
				SET FILTER TO AllTrim(F1_DOC) = Alltrim(aCabec[3,2]) .AND. AllTrim(F1_SERIE) == aCabec[4,2]
				MATA103()
				dbSelectArea("SF1")
				SET FILTER TO
				RetArea(_aArea)
				Endif
				*/
				PswOrder(1)
				PswSeek(__cUserId,.T.)
				aInfo := PswRet(1)
				cAssunto := 'Geração da pre nota '+Alltrim(aCabec[3,2])+' Serie '+Alltrim(aCabec[4,2])
				cTexto   := 'A pre nota '+Alltrim(aCabec[3,2])+' Serie: '+Alltrim(aCabec[4,2]) +' do tipo '+Alltrim(aCabec[1,2]) + ' do fornecedor '+ Alltrim(aCabec[6,2])+' loja ' + Alltrim(aCabec[7,2]) + ' foi gerada com sucesso. Por gentileza Classifique a Pré-Nota na rotina DOC.ENTRADA.'
//				cTexto   := 'A pre nota '+Alltrim(aCabec[3,2])+' Serie: '+Alltrim(aCabec[4,2]) +' do tipo '+Alltrim(aCabec[1,2]) + ' do fornecedor '+ Alltrim(aCabec[6,2])+' loja ' + Alltrim(aCabec[7,2]) + ' foi gerada com sucesso pelo usuario '+ aInfo[1,4] + ' favor classificar a pre nota em nota'	//POLIESTER
				cAuxMail := alltrim(UsrRetMail(RetCodUsr()))
				if empty(cAuxMail)
					cAuxMail := alltrim(UsrRetMail("000000"))
				endif 
				cPara    := cAuxMail
				cCC      := ''
				cArquivo := ''
				U_EnvMail(cAssunto,cTexto,cPara,cCC,cArquivo) //para que seja enviado um arquivo em anexo o arquivo deve estar dentro da pasta protheus_data
				
			Else
				MSGALERT(Alltrim(aCabec[3,2])+' / '+Alltrim(aCabec[4,2])+" - Pré Nota Não Gerada - Tente Novamente !")
			EndIf
		EndIf
	Endif
Enddo
PutMV("MV_PCNFE",lPcNfe)
Return




Static Function C(nTam)
Local nHRes	:=	oMainWnd:nClientWidth	// Resolucao horizontal do monitor
If nHRes == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)
	nTam *= 0.8
ElseIf (nHRes == 798).Or.(nHRes == 800)	// Resolucao 800x600
	nTam *= 1
Else	// Resolucao 1024x768 e acima
	nTam *= 1.28
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Tratamento para tema "Flat"³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If "MP8" $ oApp:cVersion
	If (Alltrim(GetTheme()) == "FLAT") .Or. SetMdiChild()
		nTam *= 0.90
	EndIf
EndIf
Return Int(nTam)

Static Function ValProd()
	_DESCdigit=Alltrim(GetAdvFVal("SB1","B1_DESC",XFilial("SB1")+cEdit1,1,""))
	_NCMdigit=GetAdvFVal("SB1","B1_POSIPI",XFilial("SB1")+cEdit1,1,"")
Return(ExistCpo("SB1"))

Static Function Troca()  
Local lBloqueado,nIpi
Chkproc=.T.
cProduto=cEdit1
If Empty(SB1->B1_POSIPI) .and. !Empty(cNCM) .and. cNCM != '00000000' //Emerson Holanda alterar o ncm se houver discrepancia
	dbselectarea("SYD")
	dbsetorder(1)
	dbseek(xFilial("SYD")+PADR(cNCM,TamSx3("YD_TEC")[1])+SB1->B1_EX_NCM+B1_EX_NBM)
	nIpi := iif(found(),SYD->YD_PER_IPI,0)
	dbselectarea("SB1")
	RecLock("SB1",.F.)
	Replace B1_POSIPI with cNCM
	replace B1_IPI with nIpi
	MSUnLock()
Endif

_oDlg:End()
Return(.t.)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Chk_File  ºAutor  ³                    º Data ³             º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Chamado pelo grupo de perguntas EESTR1			          º±±
±±º          ³Verifica se o arquivo em &cVar_MV (MV_PAR06..NN) existe.    º±±
±±º          ³Se não existir abre janela de busca e atribui valor a       º±±
±±º          ³variavel Retorna .T.										  º±±
±±º          ³Se usuário cancelar retorna .F.							  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³Texto da Janela		                                      º±±
±±º          ³Variavel entre aspas.                                       º±±
±±º          ³Ex.: Chk_File("Arquivo Destino","mv_par06")                 º±±
±±º          ³VerificaSeExiste? Logico - Verifica se arquivo existe ou    º±±
±±º          ³nao - Indicado para utilizar quando o arquivo eh novo.      º±±
±±º          ³Ex. Arqs. Saida.                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³                                                            º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function Chk_F(cTxt, cVar_MV, lChkExiste)
Local lExiste := File(&cVar_MV)
Local cTipo := "Arquivos XML   (*.XML)  | *.XML | Todos os Arquivos (*.*)    | *.* "
Local cArquivo := ""

//Verifica se arquivo não existe
If lExiste == .F. .or. !lChkExiste
	cArquivo := cGetFile( cTipo,OemToAnsi(cTxt))
	If !Empty(cArquivo)
		lExiste := .T.
		&cVar_Mv := cArquivo
	Endif
Endif
Return (lExiste .or. !lChkExiste)

******************************************
Static Function MarcarTudo()
DbSelectArea('TC9')
dbGoTop()
While !Eof()
	MsProcTxt('Aguarde...')
	RecLock('TC9',.F.)
	TC9->T9_OK := _cMarca
	MsUnlock()
	DbSkip()
EndDo
DbGoTop()
DlgRefresh(oDlgPedidos)
SysRefresh()
Return(.T.)

******************************************
Static Function DesmarcaTudo()
DbSelectArea('TC9')
dbGoTop()
While !Eof()
	MsProcTxt('Aguarde...')
	RecLock('TC9',.F.)
	TC9->T9_OK := ThisMark()
	MsUnlock()
	DbSkip()
EndDo
DbGoTop()
DlgRefresh(oDlgPedidos)
SysRefresh()
Return(.T.)


******************************************
Static Function Marcar()
DbSelectArea('TC9')
RecLock('TC9',.F.)
If Empty(TC9->T9_OK)
	TC9->T9_OK := _cMarca
Endif
MsUnlock()
SysRefresh()
Return(.T.)

******************************************************
Static FUNCTION Cria_TC9()

If Select("TC9") <> 0
	TC9->(dbCloseArea())
Endif
If Select("TC8") <> 0
	TC8->(dbCloseArea())
Endif


aFields   := {}
AADD(aFields,{"T9_OK"     ,"C",02,0})
AADD(aFields,{"T9_PEDIDO" ,"C",06,0})
AADD(aFields,{"T9_ITEM"   ,"C",04,0})
AADD(aFields,{"T9_PRODUTO","C",15,0})
AADD(aFields,{"T9_DESC"   ,"C",40,0})
AADD(aFields,{"T9_UM"     ,"C",02,0})
AADD(aFields,{"T9_QTDE"   ,"N",6,0})
AADD(aFields,{"T9_UNIT"   ,"N",12,2})
AADD(aFields,{"T9_TOTAL"  ,"N",14,2})
AADD(aFields,{"T9_DTPRV"  ,"D",08,0})
AADD(aFields,{"T9_ALMOX"  ,"C",02,0})
AADD(aFields,{"T9_OBSERV" ,"C",30,0})
AADD(aFields,{"T9_CCUSTO" ,"C",06,0})
AADD(aFields,{"T9_TES" ,"C",3,0})
AADD(aFields,{"T9_REG" ,"N",10,0})
cArq:=Criatrab(aFields,.T.)
DBUSEAREA(.t.,,cArq,"TC9")

aFields2   := {}
AADD(aFields2,{"T8_NOTA" ,"C",09,0})
AADD(aFields2,{"T8_SERIE"   ,"C",03,0})
AADD(aFields2,{"T8_PRODUTO","C",15,0})
AADD(aFields2,{"T8_DESC"   ,"C",40,0})
AADD(aFields2,{"T8_UM"     ,"C",02,0})
AADD(aFields2,{"T8_QTDE"   ,"N",6,0})
AADD(aFields2,{"T8_UNIT"   ,"N",12,2})
AADD(aFields2,{"T8_TOTAL"  ,"N",14,2})
cArq2:=Criatrab(aFields2,.T.)
DBUSEAREA(.t.,,cArq2,"TC8")
Return


********************************************
Static Function Monta_TC9()
// Irá efetuar a checagem de pedidos de compras
// em aberto para este fornecedor e os itens desta nota fiscal a ser importa
// será demonstrado ao usuário se o pedido de compra deverá ser associado
// a entrada desta nota fiscal

cQuery := ""
cQuery += " SELECT  C7_NUM T9_PEDIDO,     "
cQuery += " 		C7_ITEM T9_ITEM,    "
cQuery += " 	    C7_PRODUTO T9_PRODUTO, "
cQuery += " 		B1_DESC T9_DESC,    "
cQuery += " 		B1_UM T9_UM,		"
cQuery += " 		C7_QUANT T9_QTDE,   "
cQuery += " 		C7_PRECO T9_UNIT,   "
cQuery += " 		C7_TOTAL T9_TOTAL,   "
cQuery += " 		C7_DATPRF T9_DTPRV,  "
cQuery += " 		C7_LOCAL T9_ALMOX, "
cQuery += " 		C7_OBS T9_OBSERV, "
cQuery += " 		C7_CC T9_CCUSTO, "
cQuery += " 		C7_TES T9_TES, "
cQuery += " 		SC7.R_E_C_N_O_ T9_REG "
cQuery += " FROM " + RetSqlName("SC7") + " SC7 WITH (NOLOCK) " + ;
"LEFT OUTER JOIN "+RetSqlName("SB1") + " SB1 WITH (NOLOCK) ON (SB1.D_E_L_E_T_ <> '*') AND (SB1.B1_FILIAL = '"+xFilial("SB1")+"') AND (C7_PRODUTO = B1_COD) "
cQuery += " WHERE (C7_FILIAL = '" + xFilial("SC7") + "') "
cQuery += " AND (SC7.D_E_L_E_T_ <> '*') "
cQuery += " AND (C7_QUANT > C7_QUJE)  "
cQuery += " AND (C7_RESIDUO = '')  "
//	cQuery += " AND C7_TPOP <> 'P'  "
cQuery += " AND (C7_CONAPRO <> 'B')  "
cQuery += " AND (C7_ENCER = '') "
//	cQuery += " AND C7_CONTRA = '' "
//	cQuery += " AND C7_MEDICAO = '' "
cQuery += " AND (C7_FORNECE = '" + SA2->A2_COD + "') "
cQuery += " AND (C7_LOJA = '" + SA2->A2_LOJA + "') "
cQuery += " AND C7_PRODUTO IN" + FormatIn( cProds, "/")
If MV_PAR01 <> 1
	cQuery += " AND 1 > 1 "
Endif
cQuery += " ORDER BY C7_NUM, C7_ITEM, C7_PRODUTO "
//cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"CAD",.T.,.T.)
TcSetField("CAD","T9_DTPRV","D",8,0)

Dbselectarea("CAD")

While CAD->(!EOF())
	RecLock("TC9",.T.)
	For _nX := 1 To Len(aFields)
		If !(aFields[_nX,1] $ 'T9_OK')
			If aFields[_nX,2] = 'C'
				_cX := 'TC9->'+aFields[_nX,1]+' := Alltrim(CAD->'+aFields[_nX,1]+')'
			Else
				_cX := 'TC9->'+aFields[_nX,1]+' := CAD->'+aFields[_nX,1]
			Endif
			_cX := &_cX
		Endif
	Next
	TC9->T9_OK := _cMarca //ThisMark()
	MsUnLock()
	
	DbSelectArea('CAD')
	CAD->(dBSkip())
EndDo

Dbselectarea("CAD")
DbCloseArea()
Dbselectarea("TC9")
DbGoTop()

_cIndex:=Criatrab(Nil,.F.)
_cChave:="T9_PEDIDO"
Indregua("TC9",_cIndex,_cChave,,,"Ordenando registros selecionados...")
DbSetIndex(_cIndex+ordbagext())
SysRefresh()
Return


Static Function GetArq(cArquivo)

	cArquivo:= cGetFile( "Arquivo NFe (*.xml) | *.xml", "Selecione o Arquivo de Nota Fiscal XML",,Caminho,.F.,nOr(GETF_LOCALHARD,GETF_NETWORKDRIVE) ) //Exerga Unidade Mapeadas - Poliester
Return(cArquivo)


StatiC Function Fecha()
Close(_oPT00005)     
lOut := .t.
Return

Static Function AchaFile(cArquivo)
Local aCompl := {}
Local cCaminho
Local lOk := .f.
Local nHdl,cArquivo,aFiles,nArq,nTamFile,nBtLidos,cBuffer,cChave,i

cChave := alltrim(cCodBar)
If Empty(cChave)
	Return(.t.)
Endif

if len(cChave) != 44
	MsgAlert("Tamanho da chave deverá ter 44 dígitos! Corrija por favor", "Atencao!")
	return(.f.)
endif 	

for i := 1 to 2  
	cCaminho := alltrim(Caminho)
	if substr(cCaminho,len(cCaminho),1) != "\"
		cCaminho += "\"
	endif 
	if i == 2
		cCaminho += "PROCESSADOS\"
	endif 
	aFiles := Directory(cCaminho+"*.XML", "D")

	For nArq := 1 To Len(aFiles)
		cArquivo := AllTrim(cCaminho+aFiles[nArq,1])
	
		nHdl    := fOpen(cArquivo,0)
		If nHdl < 0
	 		MsgAlert("O arquivo de nome "+cArquivo+" nao pode ser aberto! ERRO:"+StrZero(FERROR(), 1)+"!", "Atencao!")
    	    loop      
	   	Endif
		nTamFile := fSeek(nHdl,0,2)
		fSeek(nHdl,0,0)
		cBuffer  := Space(nTamFile)                // Variavel para criacao da linha do registro para leitura
		nBtLidos := fRead(nHdl,@cBuffer,nTamFile)  // Leitura  do arquivo XML
		fClose(nHdl)
		If AT(AllTrim(cChave),AllTrim(cBuffer)) > 0
			lOk := .t.
			Exit
		Endif
	Next
	if lOk
		exit
	endif 
next 
If !lOk
	cArquivo := ""
	MsgAlert("Nenhum Arquivo Encontrado, Por Favor Selecione a Opção Arquivo e Faça a Busca na Arvore de Diretórios!")  
Endif

Return(lOk)

// Funcao de ENvio de Email de Aviso de PRe Nota

User Function EnvMail(_cSubject, _cBody, _cMailTo, _cCC, _cAnexo, _cConta, _cSenha)
Local _cMailS		:= GetMv("MV_RELSERV")
Local _cAccount		:= GetMV("MV_RELACNT")
Local _cPass		:= GetMV("MV_RELFROM")
Local _cSenha2		:= GetMV("MV_RELPSW")
Local _cUsuario2	:= GetMV("MV_RELACNT")
Local lAuth			:= GetMv("MV_RELAUTH",,.F.)

Connect Smtp Server _cMailS Account _cAccount Password _cPass RESULT lResult

If lAuth		// Autenticacao da conta de e-mail
	lResult := MailAuth(_cUsuario2, _cSenha2)
	If !lResult
		Alert("Não foi possivel autenticar a conta - " + _cUsuario2)	//É melhor a mensagem aparecer para o usuário do que no console ou no log.txt - Poliester
//		ConOut("Nao foi possivel autenticar a conta - " + _cUsuario2)
		Return()
	EndIf
EndIf

_xx := 0

lResult := .F.

do while !lResult
	
	If !Empty(_cAnexo)
		Send Mail From _cAccount To _cMailTo CC _cCC Subject _cSubject Body _cBody ATTACHMENT _cAnexo RESULT lResult
	Else
		Send Mail From _cAccount To _cMailTo CC _cCC Subject _cSubject Body _cBody RESULT lResult
	Endif
	
	_xx++
	if _xx > 2
		Exit
	Else
		Get Mail Error cErrorMsg
		ConOut(cErrorMsg)
	EndIf
EndDo
Return