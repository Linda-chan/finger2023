#define NUL       Chr(0)
#define NULNUL    Chr(0) & Chr(0)
#define CR        Chr(13)
#define LF        Chr(10)
#define CRLF      Chr(13) & Chr(10)
#define CRLFCRLF  Chr(13) & Chr(10) & Chr(13) & Chr(10)
#define CRCRLF    Chr(13) & Chr(13) & Chr(10)
#define A_TAB     Chr(9)
#define V_TAB     Chr(11)
#define BS        Chr(8)
#define FF        Chr(12)
#define BEL       Chr(7)
#define ESC       Chr(27)

' Не пахаить...
'#define TODO(param) #print __FILE_NQ__(__LINE__) ==> TODO: param

' Пахаить...
#define TODO_2(param_1, param_2, param_3) #print param_1(param_2) ==> TODO: param_3
#define TODO(param) TODO_2(__FILE_NQ__, __LINE__, param)

#define MyTrim(param) Trim(param, Any !" \t")
#define MyTrim2(param) Trim(param, Any !" \t\r\n")
#define MyLTrim(param) LTrim(param, Any !" \t")
#define MyLTrim2(param) LTrim(param, Any !" \t\r\n")
#define MyRTrim(param) RTrim(param, Any !" \t")
#define MyRTrim2(param) RTrim(param, Any !" \t\r\n")

' Проверяет, открыт ли файл, и закрывает его, если открыт. Дело 
' в том, что в VB закрытие неоткрытого файла не вызывает ошибки, 
' а в FB – вызывает =_=
' 
' Так же проверяем сам номер файла. Дело в том, что тот же 0 хоть 
' и не верен, но FileAttr() для него вернёт какой-то хэндл! ХЗ что 
' это, но допускать такого нельзя!
#macro MyClose ? (file_num)
	If file_num > 0 And file_num < 256 Then _
		If FileAttr(file_num, fbFileAttrHandle) <> 0 Then _
			Close file_num
#endmacro
