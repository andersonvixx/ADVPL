#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "ap5mail.ch" 
#Include "fivewin.ch"       

/*/
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+---------+------------------+-------------------------+----------------+¦¦
¦¦¦   	    ¦ Função: A010TOK  ¦ Autor: Thiago Moreira   ¦ Data: 12/10/08 ¦¦¦
¦¦+---------+------------------+-------------------------+----------------+¦¦
¦¦¦Descrição¦ Alerta usuários sobre inclusões e alterações no Cadastro de ¦¦¦ 
¦¦¦			¦ Produtos.													  ¦¦¦
¦¦+---------+-------------------------------------------------------------+¦¦
¦¦¦   Uso   ¦								 ¦¦¦
¦¦+---------+-------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
/*/

					
User Function A010TOK()



Private _lValid:= .F.  
Private _cCpoSX3:=""  
Private _aProd:={}      

Private _cArea:=GETAREA()


IF INCLUI 

	DBSELECTAREA("SX3")
	SX3->(DBSETORDER(1))
	SX3->(DBGOTOP())
	MsSeek("SB1",.T.)
	
	DO WHILE  ( !Eof() .AND. (ALLTRIM(SX3->X3_ARQUIVO) == "SB1") )
	
		IF ALLTRIM(SX3->X3_CONTEXT) <> "V"
		
			_cCpoSX3:= ALLTRIM(SX3->X3_CAMPO)
			
	  
			IF SX3->X3_TIPO == "C"
				  AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,M->&_cCpoSX3})
			Elseif SX3->X3_TIPO == "N"	  
			      AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,STR(M->&_cCpoSX3)})	  
			Elseif SX3->X3_TIPO == "D"	  
			      AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,DTOC(M->&_cCpoSX3)})
			Elseif SX3->X3_TIPO == "M"	  
			      AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,MEMOREAD(M->&_cCpoSX3)})
			Endif                                                              
			
			_cCpoSX3:=""
		
		ENDIF
		
		SX3->(DBSKIP())
	
	
	ENDDO

	MsgRun(PadC("Aguarde. Notificando Cadastro!",100),,{|| CursorWait(),FMail8a(_aProd),CursorArrow()})    
	
Elseif ALTERA

	DBSELECTAREA("SX3")
	SX3->(DBSETORDER(1))
	SX3->(DBGOTOP())
	MsSeek("SB1",.T.)
	
	DO WHILE  ( !Eof() .AND. (ALLTRIM(SX3->X3_ARQUIVO) == "SB1") )
	
		IF ALLTRIM(SX3->X3_CONTEXT) <> "V"
			_cCpoSX3:= ALLTRIM(SX3->X3_CAMPO)
			
			IF SB1->&_cCpoSX3 <> M->&_cCpoSX3 
			  _lValid:=.T.
			  
			  IF SX3->X3_TIPO == "C"
			  	  AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,SB1->&_cCpoSX3,M->&_cCpoSX3})
			  Elseif SX3->X3_TIPO == "N"	  
			      AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,STR(SB1->&_cCpoSX3),STR(M->&_cCpoSX3)})	  
			  Elseif SX3->X3_TIPO == "D"	  
			      AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,DTOC(SB1->&_cCpoSX3),DTOC(M->&_cCpoSX3)})
			  Elseif SX3->X3_TIPO == "M"	  
			      AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,MEMOREAD(SB1->&_cCpoSX3),MEMOREAD(M->&_cCpoSX3)})
			  Endif
			      
			Endif                                                                           
			
			_cCpoSX3:=""
		
		ENDIF
		
		SX3->(DBSKIP())
	
	
	ENDDO
	
	IF _lValid == .T.
	
		MsgRun(PadC("Aguarde. Notificando Alteração!",100),,{|| CursorWait(),FMail9a(_aProd),CursorArrow()})
	
	Endif
	
Endif

RestArea(_cArea)

Return(.T.)


/*/
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+---------+------------------+-------------------------+----------------+¦¦
¦¦¦   	    ¦ Função: FMail9   ¦ Autor: Thiago Moreira   ¦ Data: 12/10/08 ¦¦¦
¦¦+---------+------------------+-------------------------+----------------+¦¦
¦¦¦Descrição¦ Envia e-mail de alteração de cadastro de produtos			  ¦¦¦
¦¦+---------+-------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
/*/
                     			
Static Function FMail9a(_aProd)


Local _cBody     := "" 
Local cItens	 :=""
Local _cSerMail	 := alltrim(GetMV("MV_RELSERV"))
Local _cConta  	 := alltrim(GetMV("MV_RELACNT"))
Local  _cSenha	 := alltrim(GetMV("MV_RELPSW"))
Local _nTimeOut  := GetMv("MV_RELTIME")

Local _cDest  := GetMv("MV_XMAILPR")

Local _lEnviado	 := .F.
Local _lConectou := .F.
Local _cMailError:= ""
Local _cTitulo   := OemtoAnsi("Alerta de Alteração do Cadastro de Produtos")
Local _cDestcco  := "" 
Local i 
Local _cCor:= "white"

	                                
	
	
	_cBody += "<p align=left><b><font face=Verdana size=3 color=#336699>" 
   	_cBody += "ALTERAÇÃO DO CADASTRO DE PRODUTOS"                     
	_cBody += "</b></font><br><br><br>"                                                 
                                                       

	_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>"  
	_cBody += "USUÁRIO: "  
	_cBody += "<font face=Verdana size=1 color=#000080>"
	_cBody += + UPPER(Substr(cUsuario,7,15)) + " 
	
	
	_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>"  
	_cBody += "DATA E HORA: "  
	_cBody += "<font face=Verdana size=1 color=#000080>"
	_cBody += + DTOC(date()) + " - " + TIME() 

	
	_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>" 
	_cBody += "PRODUTO: "  
	_cBody += "<font face=Verdana size=1 color=#000080>"
	_cBody += + ALLTRIM(SB1->B1_COD) + " - " + ALLTRIM(SB1->B1_DESC) + "   



	_cBody += "<p align=left><b><font face=Verdana size=1,5 color=#000080>" 
   	_cBody += "<br><br>RELAÇAO DE CAMPOS ALTERADOS"  
	_cBody += "</b></font><br><br>"	

   

   		
		For i:=1 to Len(_aProd)
		    		
			cItens += "<tr>"
			cItens += " <td align='center' width='18%' bgcolor='"+ALLTRIM(_cCor)+"'><font size='1' face='Arial'>" + ALLTRIM(UPPER(_aProd[i][1])) + "</td>"
			cItens += " <td align='center' width='18%' bgcolor='"+ALLTRIM(_cCor)+"'><font size='1' face='Arial'>" + ALLTRIM(UPPER(_aProd[i][2])) + "</td>"
			cItens += " <td align='center' width='18%' bgcolor='"+ALLTRIM(_cCor)+"'><font size='1' face='Arial'>" + ALLTRIM(UPPER(_aProd[i][3])) + "</td>"
			cItens += " <td align='center' width='18%' bgcolor='"+ALLTRIM(_cCor)+"'><font size='1' face='Arial'>" + ALLTRIM(UPPER(_aProd[i][4])) + "</td>"

			cItens += "</tr>"
			
			IF ALLTRIM(_cCor) == "white"
				_cCor:="#E0EEEE" 
			Else
		   		_cCor:= "white"		
		   	ENDIF	
			
			
		Next i 

		_cBody += "<table border='0' align='center' cellpadding='1' cellspacing='1' bgColor=#ffffff bordercolor='#000000' width='100%'> "
		_cBody += " <tr>"
		_cBody += "   <td align='center' width='12%' bgcolor='#336699'> "
		_cBody += "   <font size='1' color='white' face='Arial'><b>CAMPO</b></font></td>"
		
		_cBody += "   <td align='center' width='12%' bgcolor='#336699'> "
		_cBody += "   <font size='1' color='white' face='Arial'><b>DESCRIÇÃO</b></font></td>" 
		
		_cBody += "   <td align='center' width='12%' bgcolor='#336699'>"
		_cBody += "   <font size='1' color='white' face='Arial'><b>ANTES</b></font></td>"  
		
		_cBody += "   <td align='center' width='12%' bgcolor='#336699'>"
		_cBody += "   <font size='1' color='white' face='Arial'><b>DEPOIS</b></font></td>"
		_cBody += "</tr>"
		_cBody += cItens
		_cBody += "</table> <br>"
     
     
	

CONNECT SMTP SERVER _cSerMail ACCOUNT _cConta PASSWORD _cSenha TIMEOUT _nTimeOut Result _lConectou 
MailAuth(_cConta,_cSenha) 

if !(_lConectou)
	GET MAIL ERROR _cMailError
else 

	SEND MAIL FROM alltrim(_cConta) ;
	To alltrim(_cDest);
	SUBJECT	alltrim(_cTitulo) ;
	Body _cBody FORMAT TEXT RESULT _lEnviado
	
	if !(_lEnviado)
		GET MAIL ERROR _cMailError 
		alert(_cMailError)
	endif
	
	DISCONNECT SMTP SERVER
endif 

 
Return


/*/
_____________________________________________________________________________
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¦¦+---------+------------------+-------------------------+----------------+¦¦
¦¦¦         ¦ Função: FMail8   ¦ Autor: Thiago Moreira   ¦ Data: 12/10/08 ¦¦¦
¦¦+---------+------------------+-------------------------+----------------+¦¦
¦¦¦Descrição¦ Envia e-mail de Inclusão do Cadastro de Produtos			  ¦¦¦
¦¦+---------+-------------------------------------------------------------+¦¦
¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
/*/
                     			
Static Function FMail8a(_aProd)


Local _cBody     := "" 
Local cItens	 :=""
Local _cSerMail	 := alltrim(GetMV("MV_RELSERV"))
Local _cConta  	 := alltrim(GetMV("MV_RELACNT"))
Local  _cSenha	 := alltrim(GetMV("MV_RELPSW"))
Local _nTimeOut  := GetMv("MV_RELTIME")

Local _lEnviado	 := .F.
Local _lConectou := .F.
Local _cMailError:= ""
Local _cTitulo   := OemtoAnsi("Alerta de Cadastro de Produto")
Local _cDest  := GetMv("MV_XMAILPR")
Local _cDestcco  := "" 
Local i 
Local _cCor:= "white"

                            
	
	
	_cBody += "<p align=left><b><font face=Verdana size=3 color=#336699>" 
   	_cBody += "UM NOVO PRODUTO ACABA DE SER CADASTRADO"                     
	_cBody += "</b></font><br><br><br>"                                                 
                                                       

	_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>"  
	_cBody += "USUÁRIO: "  
	_cBody += "<font face=Verdana size=1 color=#000080>"
	_cBody += + UPPER(Substr(cUsuario,7,15)) + " 
	
	
	_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>"  
	_cBody += "DATA E HORA: "  
	_cBody += "<font face=Verdana size=1 color=#000080>"
	_cBody += + DTOC(date()) + " - " + TIME() 

	
	_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>" 
	_cBody += "PRODUTO: "  
	_cBody += "<font face=Verdana size=1 color=#000080>"
	_cBody += + ALLTRIM(M->B1_COD) + " - " + ALLTRIM(M->B1_DESC) + "   



	_cBody += "<p align=left><b><font face=Verdana size=1,5 color=#000080>" 
   	_cBody += "<br><br>DETALHES DO CADASTRO"  
	_cBody += "</b></font><br><br>"	

   

   		
		For i:=1 to Len(_aProd)
		    		
			cItens += "<tr>"
			cItens += " <td align='center' width='18%' bgcolor='"+ALLTRIM(_cCor)+"'><font size='1' face='Arial'>" + ALLTRIM(UPPER(_aProd[i][1])) + "</td>"
			cItens += " <td align='center' width='18%' bgcolor='"+ALLTRIM(_cCor)+"'><font size='1' face='Arial'>" + ALLTRIM(UPPER(_aProd[i][2])) + "</td>"
			cItens += " <td align='center' width='18%' bgcolor='"+ALLTRIM(_cCor)+"'><font size='1' face='Arial'>" + ALLTRIM(UPPER(_aProd[i][3])) + "</td>"
			cItens += "</tr>"
			
			IF ALLTRIM(_cCor) == "white"
				_cCor:="#E0EEEE" 
			Else
		   		_cCor:= "white"		
		   	ENDIF	
			
			
		Next i 

		_cBody += "<table border='0' align='center' cellpadding='1' cellspacing='1' bgColor=#ffffff bordercolor='#000000' width='100%'> "
		_cBody += " <tr>"
		_cBody += "   <td align='center' width='12%' bgcolor='#336699'> "
		_cBody += "   <font size='1' color='white' face='Arial'><b>CAMPO</b></font></td>"
		
		_cBody += "   <td align='center' width='12%' bgcolor='#336699'> "
		_cBody += "   <font size='1' color='white' face='Arial'><b>DESCRIÇÃO</b></font></td>" 

		_cBody += "   <td align='center' width='12%' bgcolor='#336699'>"
		_cBody += "   <font size='1' color='white' face='Arial'><b>CONTEÚDO</b></font></td>"
		_cBody += "</tr>"
		_cBody += cItens
		_cBody += "</table> <br>"
     
     
	

CONNECT SMTP SERVER _cSerMail ACCOUNT _cConta PASSWORD _cSenha TIMEOUT _nTimeOut Result _lConectou 
MailAuth(_cConta,_cSenha) 

if !(_lConectou)
	GET MAIL ERROR _cMailError
else 

	SEND MAIL FROM alltrim(_cConta) ;
	To alltrim(_cDest);
	SUBJECT	alltrim(_cTitulo) ;
	Body _cBody FORMAT TEXT RESULT _lEnviado
	
	if !(_lEnviado)
		GET MAIL ERROR _cMailError 
		alert(_cMailError)
	endif
	
	DISCONNECT SMTP SERVER
endif 

 
Return                       

