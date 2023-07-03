Declare Function FixCRLF(ByVal Text As String) As String
Declare Function FixLF(ByVal Text As String) As String
Declare Function FixCR(ByVal Text As String) As String
Declare Function Replace(ByVal Expression As String, _
                         ByVal FindWhat As String, _
                         ByVal ReplaceWith As String, _
                         ByVal StartAt As Integer = 1, _
                         ByVal Count As Integer = -1, _
                         ByVal CaseSensitive As Boolean = True) As String
