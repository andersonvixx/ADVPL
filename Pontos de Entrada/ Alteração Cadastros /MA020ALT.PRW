#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
#INCLUDE "ap5mail.ch" 
//#Include "fivewin.ch"       

/*/
_____________________________________________________________________________
�����������������������������������������������������������������������������
��+---------+------------------+-------------------------+----------------+��
���   	    � Fun��o: MA020ALT � Autor: Thiago Moreira   � Data: 16/10/08 ���
��+---------+------------------+-------------------------+----------------+��
���Descri��o� Alerta usu�rios sobre altera��es no Cadastro de Fornecedores���
��+---------+-------------------------------------------------------------+��
���   Uso   �  ���
��+---------+-------------------------------------------------------------+��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/

					
User Function MA020ALT()

Private _lValid:= .F.  
Private _cCpoSX3:=""  
Private _aProd:={}      

Private _cArea:=GETAREA()


DBSELECTAREA("SX3")
SX3->(DBSETORDER(1))
SX3->(DBGOTOP())
MsSeek("SA2",.T.)

DO WHILE  (!Eof() .AND. (ALLTRIM(SX3->X3_ARQUIVO) == "SA2") )

   IF ALLTRIM(SX3->X3_CONTEXT) <> "V"
   
		_cCpoSX3:= ALLTRIM(SX3->X3_CAMPO)
		
		IF SA2->&_cCpoSX3 <> M->&_cCpoSX3 
		  _lValid:=.T.
		  
		  IF SX3->X3_TIPO == "C"
		  	  AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,SA2->&_cCpoSX3,M->&_cCpoSX3})
		  Elseif SX3->X3_TIPO == "N"	  
		      AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,STR(SA2->&_cCpoSX3),STR(M->&_cCpoSX3)})	  
		  Elseif SX3->X3_TIPO == "D"	  
		      AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,DTOC(SA2->&_cCpoSX3),DTOC(M->&_cCpoSX3)})
		  Elseif SX3->X3_TIPO == "M"	  
		      AADD(_aProd,{SX3->X3_TITULO,SX3->X3_DESCRIC,MEMOREAD(SA2->&_cCpoSX3),MEMOREAD(M->&_cCpoSX3)})
		  Endif
		      
		Endif                                                                           
		
		_cCpoSX3:=""
		
	ENDIF
	
	SX3->(DBSKIP())


ENDDO

IF _lValid == .T.

	MsgRun(PadC("Aguarde. Notificando Altera��o!",100),,{|| CursorWait(),FMail9b(_aProd),CursorArrow()})

Endif

RestArea(_cArea)

Return(.T.)


/*/
_____________________________________________________________________________
�����������������������������������������������������������������������������
��+---------+------------------+-------------------------+----------------+��
���   � Fun��o: FMail9   � Autor: Thiago Moreira   � Data: 12/10/08 ���
��+---------+------------------+-------------------------+----------------+��
���Descri��o� Envia e-mail para os destinat�rios						  ���
��+---------+-------------------------------------------------------------+��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
                     			
Static Function FMail9b(_aProd)


Local _cBody     := "" 
Local cItens	 :=""
Local _cSerMail	 := alltrim(GetMV("MV_RELSERV"))
Local _cConta  	 := alltrim(GetMV("MV_RELACNT"))
Local  _cSenha	 := alltrim(GetMV("MV_RELPSW"))
Local _nTimeOut  := GetMv("MV_RELTIME")

Local _lEnviado	 := .F.
Local _lConectou := .F.
Local _cMailError:= ""
Local _cTitulo   := OemtoAnsi("Alerta de Altera��o do Cadastro de Fornecedores")
Local _cDest     := "ronner@temperoregina.com.br;fransciso@temperoregina.com.br" //GetMv("MV_XMAILFO")
Local _cDestcco  := "" 
Local i 
Local _cCor:= "white"

                              
	
	
	_cBody += "<p align=left><b><font face=Verdana size=3 color=#336699>" 
   	_cBody += "ALTERA��O DO CADASTRO DE FORNECEDORES"                     
	_cBody += "</b></font><br><br><br>"                                                 
                                                       

	_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>"  
	_cBody += "USU�RIO: "  
	_cBody += "<font face=Verdana size=1 color=#000080>"
	_cBody += + UPPER(Substr(cUsuario,7,15)) + " 
	
	
	_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>"  
	_cBody += "DATA E HORA: "  
	_cBody += "<font face=Verdana size=1 color=#000080>"
	_cBody += + DTOC(date()) + " - " + TIME() 

	
	_cBody += "<p align=left><b><font face=Verdana size=1 color=#336699>" 
	_cBody += "FORNECEDOR: "  
	_cBody += "<font face=Verdana size=1 color=#000080>"
	_cBody += + ALLTRIM(SA2->A2_COD) + " - " + ALLTRIM(SA2->A2_NREDUZ) + "   



	_cBody += "<p align=left><b><font face=Verdana size=1,5 color=#000080>" 
   	_cBody += "<br><br>RELA�AO DE CAMPOS ALTERADOS"  
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
		_cBody += "   <font size='1' color='white' face='Arial'><b>DESCRI��O</b></font></td>" 
		
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

 
Return(.T.)        



           