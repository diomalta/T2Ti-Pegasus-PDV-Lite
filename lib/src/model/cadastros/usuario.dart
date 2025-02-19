/*
Title: T2Ti ERP 3.0                                                              
Description: Model que permite o cadastro do usuário do PDV na 
retaguarda da SH
                                                                                
The MIT License                                                                 
                                                                                
Copyright: Copyright (C) 2021 T2Ti.COM                                          
                                                                                
Permission is hereby granted, free of charge, to any person                     
obtaining a copy of this software and associated documentation                  
files (the "Software"), to deal in the Software without                         
restriction, including without limitation the rights to use,                    
copy, modify, merge, publish, distribute, sublicense, and/or sell               
copies of the Software, and to permit persons to whom the                       
Software is furnished to do so, subject to the following                        
conditions:                                                                     
                                                                                
The above copyright notice and this permission notice shall be                  
included in all copies or substantial portions of the Software.                 
                                                                                
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,                 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES                 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                        
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT                     
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,                    
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING                    
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR                   
OTHER DEALINGS IN THE SOFTWARE.                                                 
                                                                                
       The author may be contacted at:                                          
           t2ti.com@gmail.com                                                   
                                                                                
@author Albert Eije (alberteije@gmail.com)                    
@version 1.0.0
*******************************************************************************/
import 'dart:convert';

import 'package:intl/intl.dart';

class Usuario {
	int id;
	String email;
	String senha;
	DateTime dataCadastro;
	String pendente;
	String whatsapp;
	String news;

	Usuario({
			this.id,
			this.email,
			this.senha,
			this.dataCadastro,
			this.pendente,
			this.whatsapp,
			this.news,
		});

	Usuario.fromJson(Map<String, dynamic> jsonDados) {
		// id = jsonDados['id'];
		email = jsonDados['email'];
		senha = jsonDados['senha'];
		dataCadastro = jsonDados['dataCadastro'] != null ? DateTime.tryParse(jsonDados['dataCadastro']) : null;
		pendente = jsonDados['pendente'];
		whatsapp = jsonDados['whatsapp'];
		news = jsonDados['news'];
	}

	Map<String, dynamic> get toJson {
		Map<String, dynamic> jsonDados = new Map<String, dynamic>();

		// jsonDados['id'] = this.id ?? 0;
		jsonDados['email'] = this.email;
		jsonDados['senha'] = this.senha;
		jsonDados['dataCadastro'] = this.dataCadastro != null ? DateFormat('yyyy-MM-ddT00:00:00').format(this.dataCadastro) : null;
		jsonDados['pendente'] = this.pendente;
		jsonDados['whatsapp'] = this.whatsapp;
		jsonDados['news'] = this.news;
	
		return jsonDados;
	}
	
	String objetoEncodeJson(Usuario objeto) {
	  final jsonDados = objeto.toJson;
	  return json.encode(jsonDados);
	}
	
}