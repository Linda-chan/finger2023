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
