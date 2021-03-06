/* File : win32gui.i */
// @doc

%module win32gui // A module which provides an interface to the native win32 GUI
%include "typemaps.i"
%include "pywintypes.i"

%{
#undef PyHANDLE
#include "pywinobjects.h"
#include "winuser.h"
#include "commctrl.h"
#include "windowsx.h" // For edit control hacks.

#ifdef MS_WINCE
#include "winbase.h"
#endif

static PyObject *g_AtomMap = NULL; // Mapping class atoms to Python WNDPROC
static PyObject *g_HWNDMap = NULL; // Mapping HWND to Python WNDPROC
static PyObject *g_DLGMap = NULL;  // Mapping Dialog HWND to Python WNDPROC

static	HWND	hDialogCurrent = NULL;	// see MS TID Q71450 and PumpMessages for this

extern HGLOBAL MakeResourceFromDlgList(PyObject *tmpl);
extern PyObject *MakeDlgListFromResource(HGLOBAL res);


%}

// Written to the module init function.
%init %{
PyEval_InitThreads(); /* Start the interpreter's thread-awareness */
%}

%apply HCURSOR {long};
typedef long HCURSOR;

%apply HINSTANCE {long};
typedef long HINSTANCE;

%apply HMENU {long};
typedef long HMENU

%apply HICON {long};
typedef long HICON

%apply HBITMAP {long};
typedef long HBITMAP

%apply HWND {long};
typedef long HWND

%apply HDC {long};
typedef long HDC

%apply HBRUSH {long};
typedef long HBRUSH

%apply HRGN {long};
typedef long HRGN

%apply HIMAGELIST {long};
typedef long HIMAGELIST

%apply HACCEL {long};
typedef long HACCEL

%apply COLORREF {long};
typedef long COLORREF

typedef long WPARAM;
typedef long LPARAM;
typedef long LRESULT;
typedef int UINT;

%typedef void *NULL_ONLY

%typemap(python,in) NULL_ONLY {
	if ($source != Py_None) {
		PyErr_SetString(PyExc_TypeError, "This param must be None");
		return NULL;
	}
	$target = NULL;
}

%typemap(python,in) MSG *INPUT {
    $target = (MSG *)calloc(1, sizeof(MSG));
    if (!PyArg_ParseTuple($source, "iiiii(ii):MSG param for $name",
            &$target->hwnd,
            &$target->message,
            &$target->wParam,
            &$target->lParam,
            &$target->time,
            &$target->pt.x,
            &$target->pt.y)) {
        return NULL;
    }
}
%typemap(python,ignore) RECT *OUTPUT(RECT temp)
{
  $target = &temp;
}

%typemap(python,in) RECT *INPUT {
    RECT r;
	if (PyTuple_Check($source)) {
		if (PyArg_ParseTuple($source, "llll", &r.left, &r.top, &r.right, &r.bottom) == 0) {
			return PyErr_Format(PyExc_TypeError, "%s: This param must be a tuple of four integers", "$name");
		}
		$target = &r;
	} else {
		return PyErr_Format(PyExc_TypeError, "%s: This param must be a tuple of four integers", "$name");
	}
}

%typemap(python,in) RECT *INPUT_NULLOK {
    RECT r;
	if (PyTuple_Check($source)) {
		if (PyArg_ParseTuple($source, "llll", &r.left, &r.top, &r.right, &r.bottom) == 0) {
			return PyErr_Format(PyExc_TypeError, "%s: This param must be a tuple of four integers or None", "$name");
		}
		$target = &r;
	} else {
		if ($source == Py_None) {
            $target = NULL;
        } else {
            PyErr_SetString(PyExc_TypeError, "This param must be a tuple of four integers or None");
            return NULL;
		}
	}
}

%typemap(python,in) struct HRGN__ *NONE_ONLY {
 /* Currently only allow NULL as a value -- I don't know of the
    'right' way to do this.   DAA 1/9/2000 */
	if ($source == Py_None) {
        $target = NULL;
    } else {
		return PyErr_Format(PyExc_TypeError, "%s: This HRGN must currently be None", "$name");
	}
}

%typemap(python,argout) RECT *OUTPUT {
    PyObject *o;
    o = Py_BuildValue("llll", $source->left, $source->top, $source->right, $source->bottom);
    if (!$target) {
      $target = o;
    } else if ($target == Py_None) {
      Py_DECREF(Py_None);
      $target = o;
    } else {
      if (!PyList_Check($target)) {
	PyObject *o2 = $target;
	$target = PyList_New(0);
	PyList_Append($target,o2);
	Py_XDECREF(o2);
      }
      PyList_Append($target,o);
      Py_XDECREF(o);
    }
}

%typemap(python,argout) POINT *OUTPUT {
    PyObject *o;
    o = Py_BuildValue("ll", $source->x, $source->y);
    if (!$target) {
      $target = o;
    } else if ($target == Py_None) {
      Py_DECREF(Py_None);
      $target = o;
    } else {
      if (!PyList_Check($target)) {
	PyObject *o2 = $target;
	$target = PyList_New(0);
	PyList_Append($target,o2);
	Py_XDECREF(o2);
      }
      PyList_Append($target,o);
      Py_XDECREF(o);
    }
}

%typemap(python,ignore) POINT *OUTPUT(POINT temp)
{
  $target = &temp;
}

%typemap(python,in) POINT *INPUT {
    POINT r;
	if (PyTuple_Check($source)) {
		if (PyArg_ParseTuple($source, "ll", &r.x, &r.y) == 0) {
			return PyErr_Format(PyExc_TypeError, "%s: a POINT must be a tuple of integers", "$name");
		}
		$target = &r;
    } else {
		return PyErr_Format(PyExc_TypeError, "%s: a POINT must be a tuple of integers", "$name");
	}
}


%typemap(python,in) POINT *BOTH = POINT *INPUT;
%typemap(python,argout) POINT *BOTH = POINT *OUTPUT;

%typemap(python,except) LRESULT {
      Py_BEGIN_ALLOW_THREADS
      $function
      Py_END_ALLOW_THREADS
}

%typemap(python,except) BOOL {
      Py_BEGIN_ALLOW_THREADS
      $function
      Py_END_ALLOW_THREADS
}

%typemap(python,except) HWND, HDC, HMENU, HICON, HBITMAP, HIMAGELIST {
      Py_BEGIN_ALLOW_THREADS
      $function
      Py_END_ALLOW_THREADS
      if ($source==0)  {
           $cleanup
           return PyWin_SetAPIError("$name");
      }
}

%{

#ifdef STRICT
#define MYWNDPROC WNDPROC
#else
#define MYWNDPROC FARPROC
#endif

// Returns TRUE if a call was made (and the rc is in the param)
// Returns FALSE if nothing could be done (so the caller should probably
// call its default)
// NOTE: assumes thread state already acquired.
BOOL PyWndProc_Call(PyObject *obFuncOrMap, HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam, LRESULT *prc)
{
	// oldWndProc may be:
	//  NULL : Call DefWindowProc
	//  -1   : Assumed a dialog proc, and returns FALSE
	// else  : A valid WndProc to call.

	PyObject *obFunc = NULL;
	if (obFuncOrMap!=NULL) {
		if (PyDict_Check(obFuncOrMap)) {
			PyObject *key = PyInt_FromLong(uMsg);
			obFunc = PyDict_GetItem(obFuncOrMap, key);
			Py_DECREF(key);
		} else {
			obFunc = obFuncOrMap;
		}
	}
	if (obFunc==NULL) {
		PyErr_Clear();
		return FALSE;
	}
	// We are dispatching to Python...
	PyObject *args = Py_BuildValue("llll", hWnd, uMsg, wParam, lParam);
	PyObject *ret = PyObject_CallObject(obFunc, args);
	Py_DECREF(args);
	LRESULT rc = 0;
	if (ret) {
		if (ret != Py_None) // can remain zero for that!
			rc = PyInt_AsLong(ret);
		Py_DECREF(ret);
	}
	else
		PyErr_Print();
	*prc = rc;
	return TRUE;
}

LRESULT CALLBACK PyWndProcClass(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	PyObject *obFunc = (PyObject *)GetClassLong( hWnd, 0);
	LRESULT rc = 0;
	CEnterLeavePython _celp;
	if (!PyWndProc_Call(obFunc, hWnd, uMsg, wParam, lParam, &rc)) {
		_celp.release();
		rc = DefWindowProc(hWnd, uMsg, wParam, lParam);
	}
	return rc;
}

LRESULT CALLBACK PyDlgProcClass(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	PyObject *obFunc = (PyObject *)GetClassLong( hWnd, 0);
	LRESULT rc = 0;
	CEnterLeavePython _celp;
	if (!PyWndProc_Call(obFunc, hWnd, uMsg, wParam, lParam, &rc)) {
		_celp.release();
		rc = DefDlgProc(hWnd, uMsg, wParam, lParam);
	}
	return rc;
}

LRESULT CALLBACK PyWndProcHWND(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	CEnterLeavePython _celp;
	PyObject *key = PyInt_FromLong((long)hWnd);
	PyObject *obInfo = PyDict_GetItem(g_HWNDMap, key);
	Py_DECREF(key);
	MYWNDPROC oldWndProc = NULL;
	PyObject *obFunc = NULL;
	if (obInfo!=NULL) { // Is one of ours!
		obFunc = PyTuple_GET_ITEM(obInfo, 0);
		PyObject *obOldWndProc = PyTuple_GET_ITEM(obInfo, 1);
		oldWndProc = (MYWNDPROC)PyInt_AsLong(obOldWndProc);
	}
	LRESULT rc = 0;
	if (!PyWndProc_Call(obFunc, hWnd, uMsg, wParam, lParam, &rc))
		if (oldWndProc) {
			_celp.release();
			rc = CallWindowProc(oldWndProc, hWnd, uMsg, wParam, lParam);
		}

#ifdef WM_NCDESTROY
	if (uMsg==WM_NCDESTROY) {
#else // CE doesnt have this message!
	if (uMsg==WM_DESTROY) {
#endif
		_celp.acquire(); // in case we released above - safe if already acquired.
		PyObject *key = PyInt_FromLong((long)hWnd);
		if (PyDict_DelItem(g_HWNDMap, key) != 0)
			PyErr_Clear();
		Py_DECREF(key);
	}
	return rc;
}

BOOL CALLBACK PyDlgProcHDLG(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	BOOL rc = FALSE;
	CEnterLeavePython _celp;
	if (uMsg==WM_INITDIALOG) {
		// The lparam is our PyObject.
		// Put our HWND in the map.
		PyObject *obTuple = (PyObject *)lParam;
		PyObject *obWndProc = PyTuple_GET_ITEM(obTuple, 0);
		// Replace the lParam with the one the user specified.
		lParam = PyInt_AsLong( PyTuple_GET_ITEM(obTuple, 1) );
		PyObject *key = PyInt_FromLong((long)hWnd);
		if (g_DLGMap==NULL)
			g_DLGMap = PyDict_New();
		if (g_DLGMap)
			PyDict_SetItem(g_DLGMap, key, obWndProc);
		Py_DECREF(key);
		// obWndProc has no reference.
		rc = TRUE;
	} else if(uMsg == WM_ACTIVATE) {	// see MS TID Q71450 and PumpMessages
		if(0 == wParam)
			hDialogCurrent = NULL;
		else
			hDialogCurrent = hWnd;
	}
	// If our HWND is in the map, then call it.
	PyObject *obFunc = NULL;
	if (g_DLGMap) {
		PyObject *key = PyInt_FromLong((long)hWnd);
		obFunc = PyDict_GetItem(g_DLGMap, key);
		Py_XDECREF(key);
		if (!obFunc)
			PyErr_Clear();
	}
	if (obFunc) {
		LRESULT lrc;
		if (PyWndProc_Call(obFunc, hWnd, uMsg, wParam, lParam, &lrc))
			rc = (BOOL)lrc;
	}

#ifdef WM_NCDESTROY
	if (uMsg==WM_NCDESTROY) {
#else // CE doesnt have this message!
	if (uMsg==WM_DESTROY) {
#endif
		PyObject *key = PyInt_FromLong((long)hWnd);

		if (g_DLGMap != NULL)
			if (PyDict_DelItem(g_DLGMap, key) != 0)
				PyErr_Clear();
		Py_DECREF(key);
	}
	return rc;
}

#include "structmember.h"

// Support for a WNDCLASS object.
class PyWNDCLASS : public PyObject
{
public:
	WNDCLASS *GetWC() {return &m_WNDCLASS;}

	PyWNDCLASS(void);
	~PyWNDCLASS();

	/* Python support */
	static PyObject *meth_SetDialogProc(PyObject *self, PyObject *args);

	static void deallocFunc(PyObject *ob);

	static PyObject *getattr(PyObject *self, char *name);
	static int setattr(PyObject *self, char *name, PyObject *v);
#pragma warning( disable : 4251 )
	static struct memberlist memberlist[];
#pragma warning( default : 4251 )

	WNDCLASS m_WNDCLASS;
	PyObject *m_obMenuName, *m_obClassName, *m_obWndProc;
};
#define PyWNDCLASS_Check(ob)	((ob)->ob_type == &PyWNDCLASSType)

// @object PyWNDCLASS|A Python object, representing an WNDCLASS structure
// @comm Typically you create a PyWNDCLASS object, and set its properties.
// The object can then be passed to any function which takes an WNDCLASS object
PyTypeObject PyWNDCLASSType =
{
	PyObject_HEAD_INIT(&PyType_Type)
	0,
	"PyWNDCLASS",
	sizeof(PyWNDCLASS),
	0,
	PyWNDCLASS::deallocFunc,		/* tp_dealloc */
	0,		/* tp_print */
	PyWNDCLASS::getattr,				/* tp_getattr */
	PyWNDCLASS::setattr,				/* tp_setattr */
	0,						/* tp_compare */
	0,						/* tp_repr */
	0,						/* tp_as_number */
	0,	/* tp_as_sequence */
	0,						/* tp_as_mapping */
	0,
	0,						/* tp_call */
	0,		/* tp_str */
};

#define OFF(e) offsetof(PyWNDCLASS, e)

/*static*/ struct memberlist PyWNDCLASS::memberlist[] = {
	{"style",            T_INT,  OFF(m_WNDCLASS.style)}, // @prop integer|style|
//	{"cbClsExtra",       T_INT,  OFF(m_WNDCLASS.cbClsExtra)}, // @prop integer|cbClsExtra|
	{"cbWndExtra",       T_INT,  OFF(m_WNDCLASS.cbWndExtra)}, // @prop integer|cbWndExtra|
	{"hInstance",        T_INT,  OFF(m_WNDCLASS.hInstance)}, // @prop integer|hInstance|
	{"hIcon",            T_INT,  OFF(m_WNDCLASS.hIcon)}, // @prop integer|hIcon|
	{"hCursor",          T_INT,  OFF(m_WNDCLASS.hCursor)}, // @prop integer|hCursor|
	{"hbrBackground",    T_INT,  OFF(m_WNDCLASS.hbrBackground)}, // @prop integer|hbrBackground|
	{NULL}	/* Sentinel */
};

static PyObject *meth_SetDialogProc(PyObject *self, PyObject *args)
{
	if (!PyArg_ParseTuple(args, ":SetDialogProc"))
		return NULL;
	PyWNDCLASS *pW = (PyWNDCLASS *)self;
	pW->m_WNDCLASS.lpfnWndProc = (WNDPROC)PyDlgProcClass;
	Py_INCREF(Py_None);
	return Py_None;
}

static struct PyMethodDef PyWNDCLASS_methods[] = {
	{"SetDialogProc",     meth_SetDialogProc, 1}, 	// @pymeth SetDialogProc|Sets the WNDCLASS to be for a dialog box.
	{NULL}
};


PyWNDCLASS::PyWNDCLASS()
{
	ob_type = &PyWNDCLASSType;
	_Py_NewReference(this);
	memset(&m_WNDCLASS, 0, sizeof(m_WNDCLASS));
	m_WNDCLASS.cbClsExtra = sizeof(PyObject *);
	m_WNDCLASS.lpfnWndProc = PyWndProcClass;
	m_obMenuName = m_obClassName = m_obWndProc = NULL;
}

PyWNDCLASS::~PyWNDCLASS(void)
{
	Py_XDECREF(m_obMenuName);
	Py_XDECREF(m_obClassName);
	Py_XDECREF(m_obWndProc);
}

PyObject *PyWNDCLASS::getattr(PyObject *self, char *name)
{
	PyObject *ret = Py_FindMethod(PyWNDCLASS_methods, self, name);
	if (ret != NULL)
		return ret;
	PyErr_Clear();
	PyWNDCLASS *pW = (PyWNDCLASS *)self;
	// @prop string/<o PyUnicode>|lpszMenuName|
	// @prop string/<o PyUnicode>|lpszClassName|
	// @prop function|lpfnWndProc|
	if (strcmp("lpszMenuName", name)==0) {
		ret = pW->m_obMenuName ? pW->m_obMenuName : Py_None;
		Py_INCREF(ret);
		return ret;
	}
	if (strcmp("lpszClassName", name)==0) {
		ret = pW->m_obClassName ? pW->m_obClassName : Py_None;
		Py_INCREF(ret);
		return ret;
	}
	if (strcmp("lpfnWndProc", name)==0) {
		ret = pW->m_obWndProc ? pW->m_obWndProc : Py_None;
		Py_INCREF(ret);
		return ret;
	}
	return PyMember_Get((char *)self, memberlist, name);
}

int SetTCHAR(PyObject *v, PyObject **m, LPCTSTR *ret)
{
#ifdef UNICODE
	if (!PyUnicode_Check(v)) {
		PyErr_SetString(PyExc_TypeError, "Object must be a Unicode");
		return -1;
	}
	Py_XDECREF(*m);
	*m = v;
	Py_INCREF(v);
	*ret = PyUnicode_AsUnicode(v);
	return 0;
#else
	if (!PyString_Check(v)) {
		PyErr_SetString(PyExc_TypeError, "Object must be a string");
		return -1;
	}
	Py_XDECREF(*m);
	*m = v;
	Py_INCREF(v);
	*ret = PyString_AsString(v);
	return 0;
#endif
}
int PyWNDCLASS::setattr(PyObject *self, char *name, PyObject *v)
{
	if (v == NULL) {
		PyErr_SetString(PyExc_AttributeError, "can't delete WNDCLASS attributes");
		return -1;
	}
	PyWNDCLASS *pW = (PyWNDCLASS *)self;
	if (strcmp("lpszMenuName", name)==0) {
		return SetTCHAR(v, &pW->m_obMenuName, &pW->m_WNDCLASS.lpszMenuName);
	}
	if (strcmp("lpszClassName", name)==0) {
		return SetTCHAR(v, &pW->m_obClassName, &pW->m_WNDCLASS.lpszClassName);
	}
	if (strcmp("lpfnWndProc", name)==0) {
		if (!PyCallable_Check(v) && !PyDict_Check(v)) {
			PyErr_SetString(PyExc_TypeError, "lpfnWndProc must be callable, or a dictionary");
			return -1;
		}
		Py_XDECREF(pW->m_obWndProc);
		pW->m_obWndProc = v;
		Py_INCREF(v);
		return 0;
	}
	return PyMember_Set((char *)self, memberlist, name, v);
}

/*static*/ void PyWNDCLASS::deallocFunc(PyObject *ob)
{
	delete (PyWNDCLASS *)ob;
}

static PyObject *MakeWNDCLASS(PyObject *self, PyObject *args)
{
	if (!PyArg_ParseTuple(args, ""))
		return NULL;
	return new PyWNDCLASS();
}

%}
%native (WNDCLASS) MakeWNDCLASS;

%{

// Support for a LOGFONT object.
class PyLOGFONT : public PyObject
{
public:
	LOGFONT *GetLF() {return &m_LOGFONT;}

	PyLOGFONT(void);
	PyLOGFONT(const LOGFONT *pLF);
	~PyLOGFONT();

	/* Python support */

	static void deallocFunc(PyObject *ob);

	static PyObject *getattr(PyObject *self, char *name);
	static int setattr(PyObject *self, char *name, PyObject *v);
#pragma warning( disable : 4251 )
	static struct memberlist memberlist[];
#pragma warning( default : 4251 )

	LOGFONT m_LOGFONT;
};
#define PyLOGFONT_Check(ob)	((ob)->ob_type == &PyLOGFONTType)

// @object PyLOGFONT|A Python object, representing an PyLOGFONT structure
// @comm Typically you create a PyLOGFONT object, and set its properties.
// The object can then be passed to any function which takes an LOGFONT object
PyTypeObject PyLOGFONTType =
{
	PyObject_HEAD_INIT(&PyType_Type)
	0,
	"PyLOGFONT",
	sizeof(PyLOGFONT),
	0,
	PyLOGFONT::deallocFunc,		/* tp_dealloc */
	0,		/* tp_print */
	PyLOGFONT::getattr,				/* tp_getattr */
	PyLOGFONT::setattr,				/* tp_setattr */
	0,						/* tp_compare */
	0,						/* tp_repr */
	0,						/* tp_as_number */
	0,	/* tp_as_sequence */
	0,						/* tp_as_mapping */
	0,
	0,						/* tp_call */
	0,		/* tp_str */
};
#undef OFF
#define OFF(e) offsetof(PyLOGFONT, e)

/*static*/ struct memberlist PyLOGFONT::memberlist[] = {
	{"lfHeight",           T_LONG,  OFF(m_LOGFONT.lfHeight)}, // @prop integer|lfHeight|
	{"lfWidth",            T_LONG,  OFF(m_LOGFONT.lfWidth)}, // @prop integer|lfWidth|
	{"lfEscapement",       T_LONG,  OFF(m_LOGFONT.lfEscapement)}, // @prop integer|lfEscapement|
	{"lfOrientation",      T_LONG,  OFF(m_LOGFONT.lfOrientation)}, // @prop integer|lfOrientation|
	{"lfWeight",           T_LONG,  OFF(m_LOGFONT.lfWeight)}, // @prop integer|lfWeight|
	{"lfItalic",           T_BYTE,  OFF(m_LOGFONT.lfItalic)}, // @prop integer|lfItalic|
	{"lfUnderline",        T_BYTE,  OFF(m_LOGFONT.lfUnderline)}, // @prop integer|lfUnderline|
	{"lfStrikeOut",        T_BYTE,  OFF(m_LOGFONT.lfStrikeOut)}, // @prop integer|lfStrikeOut|
	{"lfCharSet",          T_BYTE,  OFF(m_LOGFONT.lfCharSet)}, // @prop integer|lfCharSet|
	{"lfOutPrecision",     T_BYTE,  OFF(m_LOGFONT.lfOutPrecision)}, // @prop integer|lfOutPrecision|
	{"lfClipPrecision",    T_BYTE,  OFF(m_LOGFONT.lfClipPrecision)}, // @prop integer|lfClipPrecision|
	{"lfQuality",          T_BYTE,  OFF(m_LOGFONT.lfQuality)}, // @prop integer|lfQuality|
	{"lfPitchAndFamily",   T_BYTE,  OFF(m_LOGFONT.lfPitchAndFamily)}, // @prop integer|lfPitchAndFamily|
	{NULL}	/* Sentinel */
};


PyLOGFONT::PyLOGFONT()
{
	ob_type = &PyLOGFONTType;
	_Py_NewReference(this);
	memset(&m_LOGFONT, 0, sizeof(m_LOGFONT));
}

PyLOGFONT::PyLOGFONT(const LOGFONT *pLF)
{
	ob_type = &PyLOGFONTType;
	_Py_NewReference(this);
	memcpy(&m_LOGFONT, pLF, sizeof(m_LOGFONT));
}

PyLOGFONT::~PyLOGFONT(void)
{
}

PyObject *PyLOGFONT::getattr(PyObject *self, char *name)
{
	PyLOGFONT *pL = (PyLOGFONT *)self;
	if (strcmp("lfFaceName", name)==0) {
		return PyWinObject_FromTCHAR(pL->m_LOGFONT.lfFaceName);
	}
	return PyMember_Get((char *)self, memberlist, name);
}

int PyLOGFONT::setattr(PyObject *self, char *name, PyObject *v)
{
	if (v == NULL) {
		PyErr_SetString(PyExc_AttributeError, "can't delete LOGFONT attributes");
		return -1;
	}
	if (strcmp("lfFaceName", name)==0) {
		PyLOGFONT *pL = (PyLOGFONT *)self;
		TCHAR *face;
		if (!PyWinObject_AsTCHAR(v, &face))
			return NULL;
		_tcsncpy( pL->m_LOGFONT.lfFaceName, face, LF_FACESIZE );
		return 0;
	}
	return PyMember_Set((char *)self, memberlist, name, v);
}

/*static*/ void PyLOGFONT::deallocFunc(PyObject *ob)
{
	delete (PyLOGFONT *)ob;
}

static PyObject *MakeLOGFONT(PyObject *self, PyObject *args)
{
	if (!PyArg_ParseTuple(args, ""))
		return NULL;
	return new PyLOGFONT();
}

BOOL CALLBACK EnumFontFamProc(const LOGFONT FAR *lpelf, const TEXTMETRIC *lpntm, DWORD FontType, LPARAM lParam)
{
	PyObject *obFunc;
	PyObject *obExtra;
	if (!PyArg_ParseTuple((PyObject *)lParam, "OO", &obFunc, &obExtra))
		return 0;
	PyObject *FontArg = new PyLOGFONT(lpelf);
	PyObject *params = Py_BuildValue("OOiO", FontArg, Py_None, FontType, obExtra);
	Py_XDECREF(FontArg);

	long iret = 0;
	PyObject *ret = PyObject_CallObject(obFunc, params);
	Py_XDECREF(params);
	if (ret) {
		iret = PyInt_AsLong(ret);
		Py_DECREF(ret);
	}
	return iret;
}

// @pyswig int|EnumFontFamilies|Enumerates the available font families.
static PyObject *PyEnumFontFamilies(PyObject *self, PyObject *args)
{
	PyObject *obFamily;
	PyObject *obProc;
	PyObject *obExtra = Py_None;
	long hdc;
	// @pyparm int|hdc||
	// @pyparm string/<o PyUnicode>|family||
	// @pyparm function|proc||The Python function called with each font family.  This function is called with 4 arguments.
	// @pyparm object|extra||An extra param passed to the enum procedure.
	if (!PyArg_ParseTuple(args, "lOO|O", &hdc, &obFamily, &obProc, &obExtra))
		return NULL;
	if (!PyCallable_Check(obProc)) {
		PyErr_SetString(PyExc_TypeError, "The 3rd argument must be callable");
		return NULL;
	}
	TCHAR *szFamily;
	if (!PyWinObject_AsTCHAR(obFamily, &szFamily, TRUE))
		return NULL;
	PyObject *lparam = Py_BuildValue("OO", obProc, obExtra);
	int rc = EnumFontFamilies((HDC)hdc, szFamily, EnumFontFamProc, (LPARAM)lparam);
	Py_XDECREF(lparam);
	PyWinObject_FreeTCHAR(szFamily);
	return PyInt_FromLong(rc);

}
%}
// @pyswig <o PyLOGFONT>|LOGFONT|Creates a LOGFONT object.
%native (LOGFONT) MakeLOGFONT;
%native (EnumFontFamilies) PyEnumFontFamilies;

%{
// @pyswig object|GetObject|
static PyObject *PyGetObject(PyObject *self, PyObject *args)
{
	long hob;
	// @pyparm int|handle||Handle to the object.
	if (!PyArg_ParseTuple(args, "l", &hob))
		return NULL;
	DWORD typ = GetObjectType((HGDIOBJ)hob);
	// @comm The result depends on the type of the handle.
	// For example, if the handle identifies a Font, a <o LOGFONT> object
	// is returned.
	switch (typ) {
		case OBJ_FONT: {
			LOGFONT lf;
			if (GetObject((HGDIOBJ)hob, sizeof(LOGFONT), &lf)==0)
				return PyWin_SetAPIError("GetObject");
			return new PyLOGFONT(&lf);
		}
		default:
			PyErr_SetString(PyExc_ValueError, "This GDI object type is not supported");
			return NULL;
	}
}
%}
%native (GetObject) PyGetObject;

%{
// @pyswig object|PyMakeBuffer|Returns a buffer object from addr,len or just len
static PyObject *PyMakeBuffer(PyObject *self, PyObject *args)
{
	long len,addr = 0;
	// @pyparm int|len||length of the buffer object
	// @pyparm int|addr||Address of the memory to reference
	if (!PyArg_ParseTuple(args, "l|l:PyMakeBuffer", &len,&addr))
		return NULL;

	if(0 == addr) 
		return PyBuffer_New(len);
	else
		return PyBuffer_FromMemory((void *) addr, len);

}
%}
%native (PyMakeBuffer) PyMakeBuffer;

%{
// @pyswig object|PyGetString|Returns a string object from an address (null terminated)
static PyObject *PyGetString(PyObject *self, PyObject *args)
{
	TCHAR *addr = 0;
	int len = -1;
	// @pyparm int|addr||Address of the memory to reference (must be null terminated)
	if (!PyArg_ParseTuple(args, "l|i:PyGetString",&addr, &len))
		return NULL;

	if (len==-1)
		len = _tcslen(addr);

    if (len == 0) return PyUnicodeObject_FromString("");
    if (IsBadReadPtr(addr, len)) {
        PyErr_SetString(PyExc_ValueError,
                        "The value is not a valid address for reading");
        return NULL;
    }
    return PyWinObject_FromTCHAR(addr, len);
}
%}
%native (PyGetString) PyGetString;

%{
// @pyswig object|PySetString|Copies a string to an address (null terminated)
static PyObject *PySetString(PyObject *self, PyObject *args)
{
	TCHAR *addr = 0;
	PyObject *str;
	TCHAR *source;
	long maxLen = 0;

	// @pyparm int|addr||Address of the memory to reference 
	// @pyparm str|String||The string to copy
	// @pyparm int|maxLen||Maximum number of chars to copy (optional)
	if (!PyArg_ParseTuple(args, "lO|l:PySetString",&addr,&str,&maxLen))
		return NULL;

	if (!PyWinObject_AsTCHAR(str, &source)) {
		PyErr_SetString(PyExc_TypeError,"String must by string type");
		return NULL;
	}

    if (!maxLen)
        maxLen = _tcslen(source)+1;

    if (IsBadWritePtr(addr, maxLen)) {
        PyErr_SetString(PyExc_ValueError,
                        "The value is not a valid address for writing");
        return NULL;
    }
    _tcsncpy( addr, source, maxLen);
	Py_INCREF(Py_None);
	return Py_None;
}
%}
%native (PySetString) PySetString;




%{
// @pyswig object|PyGetArraySignedLong|Returns a signed long from an array object at specified index
static PyObject *PyGetArraySignedLong(PyObject *self, PyObject *args)
{
	PyObject *ob;
	int offset;
	int maxlen;

	// @pyparm array|array||array object to use
	// @pyparm int|index||index of offset
	if (!PyArg_ParseTuple(args, "Oi:PyGetArraySignedLong",&ob,&offset))
		return NULL;

	PyBufferProcs *pb = ob->ob_type->tp_as_buffer;
	if (pb != NULL && pb->bf_getreadbuffer) {
		long *l;
		maxlen = pb->bf_getreadbuffer(ob,0,(void **) &l);
		if(-1 == maxlen) {
			PyErr_SetString(PyExc_ValueError,"Could not get array address");
			return NULL;
		}
		if(offset * sizeof(*l) > (unsigned)maxlen) {
			PyErr_SetString(PyExc_ValueError,"array index out of bounds");
			return NULL;
		}
		return PyInt_FromLong(l[offset]);

	} else {
			PyErr_SetString(PyExc_TypeError,"array passed is not an array");
			return NULL;
	}
}
%}
%native (PyGetArraySignedLong) PyGetArraySignedLong;

%{
// @pyswig object|PyGetBufferAddressAndLen|Returns a buffer object address and len
static PyObject *PyGetBufferAddressAndLen(PyObject *self, PyObject *args)
{
	PyObject *O = NULL;
	void *addr = NULL;
	int len = 0;

	// @pyparm int|obj||the buffer object
	if (!PyArg_ParseTuple(args, "O:PyGetBufferAddressAndLen", &O))
		return NULL;

	if(!PyBuffer_Check(O)) {
		PyErr_SetString(PyExc_TypeError,"item must be a buffer type");
		return NULL;
	}

	PyBufferProcs *pb = O->ob_type->tp_as_buffer;
	if (NULL != pb  && NULL != pb->bf_getreadbuffer) 
		len = pb->bf_getreadbuffer(O,0,&addr);

	if(NULL == addr) {
		PyErr_SetString(PyExc_ValueError,"Could not get buffer address");
		return NULL;
	}
	return Py_BuildValue("ll",(long) addr, len);
}
%}
%native (PyGetBufferAddressAndLen) PyGetBufferAddressAndLen;


%typedef TCHAR *STRING_OR_ATOM
%typedef TCHAR *STRING_OR_ATOM_CW

%typemap(python,in) STRING_OR_ATOM, STRING_OR_ATOM_CW {
	if (PyWinObject_AsTCHAR($source, &$target, TRUE))
		;
	else { 
		PyErr_Clear();
		if (PyInt_Check($source))
			$target = (LPTSTR) PyInt_AsLong($source);
		else {
			return PyErr_Format(PyExc_TypeError, 
			                    "Must pass an integer or a string (got '%s')",
			                    $source->ob_type->tp_name);
		}
	}
}

// A hack for CreateWindow - need to post-process...
%typemap(python,freearg) STRING_OR_ATOM_CW {
	if (PyUnicode_Check($target) || PyString_Check($target))
		PyWinObject_FreeTCHAR($source);
	else {
		// A HUGE HACK - set the class extra bytes.
		if (_result) {
			PyObject *obwc = PyDict_GetItem(g_AtomMap, PyInt_FromLong((ATOM)$source));
			if (obwc)
				SetClassLong(_result, 0, (long)((PyWNDCLASS *)obwc)->m_obWndProc);
		}
	}
}

%typedef TCHAR *RESOURCE_ID

%typemap(python,in) RESOURCE_ID {
#ifdef UNICODE
	if (PyUnicode_Check($source)) {
		if (!PyWinObject_AsTCHAR($source, &$target, TRUE))
			return NULL;
	}
#else
	if (PyString_Check($source)) {
		$target = PyString_AsString($source);
	}
#endif
	else {
		if (PyInt_Check($source))
			$target = MAKEINTRESOURCE(PyInt_AsLong($source));
	}
}

%typemap(python,freearg) RESOURCE_ID {
#ifdef UNICODE
	if (PyUnicode_Check($target))
		PyWinObject_FreeTCHAR($source);
#else
	if (PyString_Check($target))
		;
#endif
	else 
		;
}

// @pyswig int|GetWindowLong|
// @pyparm int|hwnd||
// @pyparm int|index||
long GetWindowLong(HWND hwnd, int index);

// @pyswig int|GetClassLong|
// @pyparm int|hwnd||
// @pyparm int|index||
long GetClassLong(HWND hwnd, int index);

// @pyswig int|SetWindowLong|
%{
static PyObject *PySetWindowLong(PyObject *self, PyObject *args)
{
	HWND hwnd;
	int index;
	PyObject *ob;
	long l;
	// @pyparm int|hwnd||The handle to the window
	// @pyparm int|index||The index of the item to set.
	// @pyparm object|value||The value to set.
	if (!PyArg_ParseTuple(args, "liO", &hwnd, &index, &ob))
		return NULL;
	switch (index) {
		// @comm If index is GWL_WNDPROC, then the value parameter
		// must be a callable object (or a dictionary) to use as the
		// new window procedure.
		case GWL_WNDPROC:
		{
			if (!PyCallable_Check(ob) && !PyDict_Check(ob)) {
				PyErr_SetString(PyExc_TypeError, "object must be callable or a dictionary");
				return NULL;
			}
			if (g_HWNDMap==NULL)
				g_HWNDMap = PyDict_New();

			PyObject *key = PyInt_FromLong((long)hwnd);
			PyObject *value = Py_BuildValue("Ol", ob, GetWindowLong(hwnd, GWL_WNDPROC));
			PyDict_SetItem(g_HWNDMap, key, value);
			Py_DECREF(value);
			Py_DECREF(key);
			l = (long)PyWndProcHWND;
			break;
		}
		default:
			if (!PyInt_Check(ob)) {
				return PyErr_Format(PyExc_TypeError, 
				                    "object must be an integer (got '%s')",
				                    ob->ob_type->tp_name);
			}
			l = PyInt_AsLong(ob);
	}
	long ret = SetWindowLong(hwnd, index, l);
	return PyInt_FromLong(ret);
}
%}
%native (SetWindowLong) PySetWindowLong;

// @pyswig int|CallWindowProc|
%{
static PyObject *PyCallWindowProc(PyObject *self, PyObject *args)
{
	long wndproc, hwnd, wparam, lparam;
	UINT msg;
	if (!PyArg_ParseTuple(args, "llill", &wndproc, &hwnd, &msg, &wparam, &lparam))
		return NULL;
	LRESULT rc;
    Py_BEGIN_ALLOW_THREADS
	rc = CallWindowProc((MYWNDPROC)wndproc, (HWND)hwnd, msg, wparam, lparam);
    Py_END_ALLOW_THREADS
	return PyInt_FromLong(rc);
}
%}
%native (CallWindowProc) PyCallWindowProc;

%{
static BOOL make_param(PyObject *ob, long *pl)
{
	long &l = *pl;
	if (ob==NULL || ob==Py_None)
		l = 0;
	else
#ifdef UNICODE
#define TCHAR_DESC "Unicode"
	if (PyUnicode_Check(ob))
		l = (long)PyUnicode_AsUnicode(ob);
#else
#define TCHAR_DESC "String"	
	if (PyString_Check(ob))
		l = (long)PyString_AsString(ob);
#endif
	else if (PyInt_Check(ob))
		l = PyInt_AsLong(ob);
	else {
		PyBufferProcs *pb = ob->ob_type->tp_as_buffer;
		if (pb != NULL && pb->bf_getreadbuffer) {
			if(-1 == pb->bf_getreadbuffer(ob,0,(void **) &l))
				return FALSE;
		} else {
			PyErr_SetString(PyExc_TypeError, "Must be a" TCHAR_DESC ", int, or buffer object");
			return FALSE;
		}
	}
	return TRUE;
}

// @pyswig int|SendMessage|Sends a message to the window.
// @pyparm int|hwnd||The handle to the Window
// @pyparm int|message||The ID of the message to post
// @pyparm int|wparam|0|An integer whose value depends on the message
// @pyparm int|lparam|0|An integer whose value depends on the message
static PyObject *PySendMessage(PyObject *self, PyObject *args)
{
	long hwnd;
	PyObject *obwparam=NULL, *oblparam=NULL;
	UINT msg;
	if (!PyArg_ParseTuple(args, "li|OO", &hwnd, &msg, &obwparam, &oblparam))
		return NULL;
	long wparam, lparam;
	if (!make_param(obwparam, &wparam))
		return NULL;
	if (!make_param(oblparam, &lparam))
		return NULL;

	LRESULT rc;
    Py_BEGIN_ALLOW_THREADS
	rc = SendMessage((HWND)hwnd, msg, wparam, lparam);
    Py_END_ALLOW_THREADS

	return PyInt_FromLong(rc);
}
%}
%native (SendMessage) PySendMessage;

#if !defined(MS_WINCE) || (_WIN32_WCE >= 420)
%{
// @pyswig int,int|SendMessageTimeout|Sends a message to the window.
// @pyparm int|hwnd||The handle to the Window
// @pyparm int|message||The ID of the message to post
// @pyparm int|wparam||An integer whose value depends on the message
// @pyparm int|lparam||An integer whose value depends on the message
// @pyparm int|flags||Send options
// @pyparm int|timeout||Timeout duration in milliseconds.
static PyObject *PySendMessageTimeout(PyObject *self, PyObject *args)
{
	long hwnd;
	PyObject *obwparam, *oblparam;
	UINT msg;
	UINT flags, timeout;
	if (!PyArg_ParseTuple(args, "liOOii", &hwnd, &msg, &obwparam, &oblparam, &flags, &timeout))
		return NULL;
	long wparam, lparam;
	if (!make_param(obwparam, &wparam))
		return NULL;
	if (!make_param(oblparam, &lparam))
		return NULL;

	LRESULT rc;
	DWORD dwresult;
	Py_BEGIN_ALLOW_THREADS
	rc = SendMessageTimeout((HWND)hwnd, msg, wparam, lparam, flags, timeout, &dwresult);
	Py_END_ALLOW_THREADS
	if (rc==0)
		return PyWin_SetAPIError("SendMessageTimeout");
	// @rdesc The result is the result of the SendMessageTimeout call, plus the last 'result' param.
	// If the timeout period expires, a pywintypes.error exception will be thrown,
	// with zero as the error code.  See the Microsoft documentation for more information.
	return Py_BuildValue("ii", rc, dwresult);
}
%}
%native (SendMessageTimeout) PySendMessageTimeout;
#endif /* !MS_WINCE || (_WIN32_WCE >= 420) */

// @pyswig |PostMessage|
// @pyparm int|hwnd||The handle to the Window
// @pyparm int|message||The ID of the message to post
// @pyparm int|wparam||An integer whose value depends on the message
// @pyparm int|lparam||An integer whose value depends on the message
BOOLAPI PostMessage(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

// @pyswig |PostThreadMessage|
// @pyparm int|threadId||The ID of the thread to post the message to.
// @pyparm int|message||The ID of the message to post
// @pyparm int|wparam||An integer whose value depends on the message
// @pyparm int|lparam||An integer whose value depends on the message
BOOLAPI PostThreadMessage(DWORD dwThreadId, UINT msg, WPARAM wParam, LPARAM lParam);

#ifndef	MS_WINCE
// @pyswig int|ReplyMessage|Used to reply to a message sent through the SendMessage function without returning control to the function that called SendMessage. 
BOOLAPI ReplyMessage(int lResult); // @pyparm int|result||Specifies the result of the message processing. The possible values are based on the message sent.
#endif	/* not MS_WINCE */

// @pyswig int|RegisterWindowMessage|Defines a new window message that is guaranteed to be unique throughout the system. The message value can be used when sending or posting messages.
// @pyparm string/unicode|name||The string
LRESULT RegisterWindowMessage(TCHAR *lpString);

// @pyswig int|DefWindowProc|
// @pyparm int|hwnd||The handle to the Window
// @pyparm int|message||The ID of the message to send
// @pyparm int|wparam||An integer whose value depends on the message
// @pyparm int|lparam||An integer whose value depends on the message
LRESULT DefWindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

%{
struct PyEnumWindowsCallback {
	PyObject *func;
	PyObject *extra;
};

BOOL CALLBACK PyEnumWindowsProc(
  HWND hwnd,      // handle to parent window
  LPARAM lParam   // application-defined value
) {
	BOOL result = TRUE;
	PyEnumWindowsCallback *cb = (PyEnumWindowsCallback *)lParam;
	CEnterLeavePython _celp;
	PyObject *args = Py_BuildValue("(iO)", hwnd, cb->extra);
	PyObject *ret = PyEval_CallObject(cb->func, args);
	Py_XDECREF(args);
	if (ret && PyInt_Check(ret))
		result = PyInt_AsLong(ret);
	Py_XDECREF(ret);
	return result;
}

// @pyswig |EnumWindows|Enumerates all top-level windows on the screen by passing the handle to each window, in turn, to an application-defined callback function. EnumWindows continues until the last top-level window is enumerated or the callback function returns FALSE
static PyObject *PyEnumWindows(PyObject *self, PyObject *args)
{
	BOOL rc;
	PyObject *obFunc, *obOther;
	// @pyparm object|callback||A Python function to be used as the callback.
	// @pyparm object|extra||Any python object - this is passed to the callback function as the second param (first is the hwnd).
	if (!PyArg_ParseTuple(args, "OO", &obFunc, &obOther))
		return NULL;
	if (!PyCallable_Check(obFunc)) {
		PyErr_SetString(PyExc_TypeError, "First param must be a callable object");
		return NULL;
	}
	PyEnumWindowsCallback cb;
	cb.func = obFunc;
	cb.extra = obOther;
    Py_BEGIN_ALLOW_THREADS
	rc = EnumWindows(PyEnumWindowsProc, (LPARAM)&cb);
    Py_END_ALLOW_THREADS
	if (!rc)
		return PyWin_SetAPIError("EnumWindows");
	Py_INCREF(Py_None);
	return Py_None;
}

#ifndef	MS_WINCE
// @pyswig |EnumThreadWindows|Enumerates all top-level windows associated with a thread on the screen by passing the handle to each window, in turn, to an application-defined callback function. EnumThreadWindows continues until the last top-level window associated with the thread is enumerated or the callback function returns FALSE
static PyObject *PyEnumThreadWindows(PyObject *self, PyObject *args)
{
	BOOL rc;
	PyObject *obFunc, *obOther;
	DWORD dwThreadId;
	// @pyparm int|dwThreadId||The id of the thread for which the windows need to be enumerated.
	// @pyparm object|callback||A Python function to be used as the callback.
	// @pyparm object|extra||Any python object - this is passed to the callback function as the second param (first is the hwnd).
	if (!PyArg_ParseTuple(args, "lOO", &dwThreadId, &obFunc, &obOther))
		return NULL;
	if (!PyCallable_Check(obFunc)) {
		PyErr_SetString(PyExc_TypeError, "Second param must be a callable object");
		return NULL;
	}
	PyEnumWindowsCallback cb;
	cb.func = obFunc;
	cb.extra = obOther;
    Py_BEGIN_ALLOW_THREADS
	rc = EnumThreadWindows(dwThreadId, PyEnumWindowsProc, (LPARAM)&cb);
    Py_END_ALLOW_THREADS
	if (!rc)
		return PyWin_SetAPIError("EnumThreadWindows");
	Py_INCREF(Py_None);
	return Py_None;
}

// @pyswig |EnumChildWindows|Enumerates the child windows that belong to the specified parent window by passing the handle to each child window, in turn, to an application-defined callback function. EnumChildWindows continues until the last child window is enumerated or the callback function returns FALSE.
static PyObject *PyEnumChildWindows(PyObject *self, PyObject *args)
{
	BOOL rc;
	PyObject *obFunc, *obOther;
	long hwnd;
	// @pyparm int|hwnd||The handle to the window to enumerate.
	// @pyparm object|callback||A Python function to be used as the callback.
	// @pyparm object|extra||Any python object - this is passed to the callback function as the second param (first is the hwnd).
	if (!PyArg_ParseTuple(args, "lOO", &hwnd, &obFunc, &obOther))
		return NULL;
	if (!PyCallable_Check(obFunc)) {
		PyErr_SetString(PyExc_TypeError, "First param must be a callable object");
		return NULL;
	}
	PyEnumWindowsCallback cb;
	cb.func = obFunc;
	cb.extra = obOther;
    Py_BEGIN_ALLOW_THREADS
	rc = EnumChildWindows((HWND)hwnd, PyEnumWindowsProc, (LPARAM)&cb);
    Py_END_ALLOW_THREADS
	if (!rc)
		return PyWin_SetAPIError("EnumChildWindows");
	Py_INCREF(Py_None);
	return Py_None;
}

#endif	/* not MS_WINCE */
%}
%native (EnumWindows) PyEnumWindows;
#ifndef	MS_WINCE
%native (EnumThreadWindows) PyEnumThreadWindows;
%native (EnumChildWindows) PyEnumChildWindows;
#endif	/* not MS_WINCE */


// @pyswig int|DialogBox|Creates a modal dialog box.
%{
static PyObject *PyDialogBox(PyObject *self, PyObject *args)
{
	/// XXX - todo - add support for a dialogproc!
	long hinst, hwnd, param=0;
	PyObject *obResId, *obDlgProc;
	BOOL bFreeString = FALSE;
	if (!PyArg_ParseTuple(args, "lOlO|l", &hinst, &obResId, &hwnd, &obDlgProc, &param))
		return NULL;
	LPTSTR resid;
	if (PyInt_Check(obResId))
		resid = (LPTSTR)MAKEINTRESOURCE(PyInt_AsLong(obResId));
	else {
		if (!PyWinObject_AsTCHAR(obResId, &resid)) {
			PyErr_Clear();
			PyErr_SetString(PyExc_TypeError, "Resource ID must be a string or int");
			return NULL;
		}
		bFreeString = TRUE;
	}
	PyObject *obExtra = Py_BuildValue("Ol", obDlgProc, param);

	int rc;
    Py_BEGIN_ALLOW_THREADS
	rc = DialogBoxParam((HINSTANCE)hinst, resid, (HWND)hwnd, PyDlgProcHDLG, (LPARAM)obExtra);
    Py_END_ALLOW_THREADS
	Py_DECREF(obExtra);
	if (bFreeString)
		PyWinObject_FreeTCHAR(resid);
	if (rc==-1)
		return PyWin_SetAPIError("DialogBox");

	return PyInt_FromLong(rc);
}
%}
%native (DialogBox) PyDialogBox;
// @pyswig int|DialogBoxParam|See <om win32gui.DialogBox>
%native (DialogBoxParam) PyDialogBox;



// @pyswig int|DialogBoxIndirect|Creates a modal dialog box from a template, see <om win32ui.CreateDialogIndirect>
%{
static PyObject *PyDialogBoxIndirect(PyObject *self, PyObject *args)
{
	/// XXX - todo - add support for a dialogproc!
	long hinst, hwnd, param=0;
	PyObject *obList, *obDlgProc;
	BOOL bFreeString = FALSE;
	if (!PyArg_ParseTuple(args, "lOlO|l", &hinst, &obList, &hwnd, &obDlgProc, &param))
		return NULL;
	
	HGLOBAL h = MakeResourceFromDlgList(obList);
	if (h == NULL)
		return NULL;

	PyObject *obExtra = Py_BuildValue("Ol", obDlgProc, param);

	int rc;
    Py_BEGIN_ALLOW_THREADS
	HGLOBAL templ = (HGLOBAL) GlobalLock(h);
	rc = DialogBoxIndirectParam((HINSTANCE)hinst, (const DLGTEMPLATE *) templ, (HWND)hwnd, PyDlgProcHDLG, (LPARAM)obExtra);
	GlobalUnlock(h);
	GlobalFree(h);
    Py_END_ALLOW_THREADS
	Py_DECREF(obExtra);
	if (rc==-1)
		return PyWin_SetAPIError("DialogBoxIndirect");

	return PyInt_FromLong(rc);
}
%}
%native (DialogBoxIndirect) PyDialogBoxIndirect;
// @pyswig int|DialogBoxIndirectParam|See <om win32gui.DialogBoxIndirect>
%native (DialogBoxIndirectParam) PyDialogBoxIndirect;


// @pyswig int|CreateDialogIndirect|Creates a modeless dialog box from a template, see <om win32ui.CreateDialogIndirect>
%{
static PyObject *PyCreateDialogIndirect(PyObject *self, PyObject *args)
{
	/// XXX - todo - add support for a dialogproc!
	long hinst, hwnd, param=0;
	PyObject *obList, *obDlgProc;
	BOOL bFreeString = FALSE;
	if (!PyArg_ParseTuple(args, "lOlO|l", &hinst, &obList, &hwnd, &obDlgProc, &param))
		return NULL;
	
	HGLOBAL h = MakeResourceFromDlgList(obList);
	if (h == NULL)
		return NULL;

	PyObject *obExtra = Py_BuildValue("Ol", obDlgProc, param);

	HWND rc;
    Py_BEGIN_ALLOW_THREADS
	HGLOBAL templ = (HGLOBAL) GlobalLock(h);
	rc = CreateDialogIndirectParam((HINSTANCE)hinst, (const DLGTEMPLATE *) templ, (HWND)hwnd, PyDlgProcHDLG, (LPARAM)obExtra);
	GlobalUnlock(h);
	GlobalFree(h);
    Py_END_ALLOW_THREADS
	Py_DECREF(obExtra);
	if (NULL == rc)
		return PyWin_SetAPIError("CreateDialogIndirect");

	return PyInt_FromLong((long) rc);

}
%}
%native (CreateDialogIndirect) PyCreateDialogIndirect;
// @pyswig int|DialogBoxIndirectParam|See <om win32gui.CreateDialogIndirect>
%native (CreateDialogIndirectParam) PyCreateDialogIndirect;

// @pyswig |EndDialog|Ends a dialog box.
// @pyparm int|hwnd||Handle to the window.
// @pyparm int|result||result

BOOLAPI EndDialog( HWND hwnd, int result );

// @pyswig HWND|GetDlgItem|Retrieves the handle to a control in the specified dialog box. 
HWND GetDlgItem( HWND hDlg, int nIDDlgItem ); 

// @pyswig HWND|SetDlgItemText|Sets the text for a window or control
BOOLAPI SetDlgItemText( HWND hDlg, int nIDDlgItem, TCHAR *text ); 

// @pyswig HWND|GetNextDlgTabItem|Retrieves a handle to the first control that has the WS_TABSTOP style that precedes (or follows) the specified control.
HWND GetNextDlgTabItem(
	HWND hDlg,       // @pyparm int|hDlg||handle to dialog box
	HWND hCtl,       // @pyparm int|hCtl||handle to known control
	BOOL bPrevious); // @pyparm int|bPrevious||direction flag

// @pyswig HWND|GetNextDlgGroupItem|Retrieves a handle to the first control in a group of controls that precedes (or follows) the specified control in a dialog box.
HWND GetNextDlgGroupItem(
	HWND hDlg,       // @pyparm int|hDlg||handle to dialog box
	HWND hCtl,       // @pyparm int|hCtl||handle to known control
	BOOL bPrevious); // @pyparm int|bPrevious||direction flag


// @pyswig |SetWindowText|Sets the window text.
BOOLAPI SetWindowText(HWND hwnd, TCHAR *text);

%{
// @pyswig string|GetWindowText|Get the window text.
static PyObject *PyGetWindowText(PyObject *self, PyObject *args)
{
    HWND hwnd;
    int len;
   
	TCHAR buffer[512];
	// @pyparm int|hwnd||The handle to the window
	if (!PyArg_ParseTuple(args, "l", &hwnd))
		return NULL;
    len = GetWindowText(hwnd, buffer, sizeof(buffer)/sizeof(TCHAR));
    if (len == 0) return PyUnicodeObject_FromString("");
	return PyWinObject_FromTCHAR(buffer, len);
}
%}
%native (GetWindowText) PyGetWindowText;

// @pyswig |InitCommonControls|Initializes the common controls.
void InitCommonControls();


// @pyswig HCURSOR|LoadCursor|Loads a cursor.
HCURSOR LoadCursor(
	HINSTANCE hInst, // @pyparm int|hinstance||The module to load from
	RESOURCE_ID name // @pyparm int|resid||The resource ID
);

// @pyswig HCURSOR|SetCursor|
HCURSOR SetCursor(
	HCURSOR hc // @pyparm int|hcursor||
);

// @pyswig HACCEL|CreateAcceleratorTable|Creates an accelerator table
%{
PyObject *PyCreateAcceleratorTable(PyObject *self, PyObject *args)
{
    int num, i;
    ACCEL *accels = NULL;
    PyObject *ret = NULL;
    PyObject *obAccels;
    HACCEL ha;
    // @pyparm ( (int, int, int), ...)|accels||A sequence of (fVirt, key, cmd),
    // as per the Win32 ACCEL structure.
    if (!PyArg_ParseTuple(args, "O:CreateAcceleratorTable", &obAccels))
        return NULL;
    if (!PySequence_Check(obAccels))
        return PyErr_Format(PyExc_TypeError, "accels must be a sequence of tuples (got '%s')",
                            obAccels->ob_type->tp_name);
    num = PySequence_Length(obAccels);
    if (num==0) {
        PyErr_SetString(PyExc_ValueError, "Can't create an accelerator with zero items");
        goto done;
    }
    accels = (ACCEL *)malloc(num * sizeof(ACCEL));
    if (!accels) {
        PyErr_NoMemory();
        goto done;
    }
    for (i=0;i<num;i++) {
        ACCEL *p = accels+i;
        PyObject *ob = PySequence_GetItem(obAccels, i);
        if (!ob) goto done;
        if (!PyArg_ParseTuple(ob, "BHH:ACCEL", &p->fVirt, &p->key, &p->cmd)) {
            Py_DECREF(ob);
            goto done;
        }
        Py_DECREF(ob);
    }
    ha = ::CreateAcceleratorTable(accels, num);
    if (ha)
        ret = PyLong_FromVoidPtr((void *)ha);
    else
        PyWin_SetAPIError("CreateAcceleratorTable");
done:
    if (accels)
        free(accels);
    return ret;
}
%}
%native (CreateAcceleratorTable) PyCreateAcceleratorTable;

// @pyswig |DestroyAccleratorTable|Destroys an accelerator table
// @pyparm int|haccel||
BOOLAPI DestroyAcceleratorTable(HACCEL haccel);

// @pyswig HMENU|LoadMenu|Loads a menu
HMENU LoadMenu(HINSTANCE hInst, RESOURCE_ID name);

// @pyswig |DestroyMenu|Destroys a previously loaded menu.
BOOLAPI DestroyMenu( HMENU hmenu );

#ifndef MS_WINCE
// @pyswig |SetMenu|Sets the window for the specified window.
BOOLAPI SetMenu( HWND hwnd, HMENU hmenu );
#endif

// @pyswig HCURSOR|LoadIcon|Loads an icon
HICON LoadIcon(HINSTANCE hInst, RESOURCE_ID name);

// @pyswig HANDLE|LoadImage|Loads a bitmap, cursor or icon
HANDLE LoadImage(HINSTANCE hInst, // @pyparm int|hinst||Handle to an instance of the module that contains the image to be loaded. To load an OEM image, set this parameter to zero. 
				 RESOURCE_ID name, // @pyparm int/string|name||Specifies the image to load. If the hInst parameter is non-zero and the fuLoad parameter omits LR_LOADFROMFILE, name specifies the image resource in the hInst module. If the image resource is to be loaded by name, the name parameter is a string that contains the name of the image resource.
				 UINT type, // @pyparm int|type||Specifies the type of image to be loaded.
				 int cxDesired, // @pyparm int|cxDesired||Specifies the width, in pixels, of the icon or cursor. If this parameter is zero and the fuLoad parameter is LR_DEFAULTSIZE, the function uses the SM_CXICON or SM_CXCURSOR system metric value to set the width. If this parameter is zero and LR_DEFAULTSIZE is not used, the function uses the actual resource width. 
				 int cyDesired, // @pyparm int|cyDesired||Specifies the height, in pixels, of the icon or cursor. If this parameter is zero and the fuLoad parameter is LR_DEFAULTSIZE, the function uses the SM_CYICON or SM_CYCURSOR system metric value to set the height. If this parameter is zero and LR_DEFAULTSIZE is not used, the function uses the actual resource height. 
				 UINT fuLoad); // @pyparm int|fuLoad||

#define	IMAGE_BITMAP	IMAGE_BITMAP
#define	IMAGE_CURSOR	IMAGE_CURSOR
#define	IMAGE_ICON		IMAGE_ICON

#define	LR_DEFAULTCOLOR	LR_DEFAULTCOLOR
#ifndef	MS_WINCE
#define	LR_CREATEDIBSECTION	LR_CREATEDIBSECTION
#define	LR_DEFAULTSIZE	LR_DEFAULTSIZE
#define	LR_LOADFROMFILE	LR_LOADFROMFILE
#define	LR_LOADMAP3DCOLORS	LR_LOADMAP3DCOLORS
#define	LR_LOADTRANSPARENT	LR_LOADTRANSPARENT
#define	LR_MONOCHROME	LR_MONOCHROME
#define	LR_SHARED	LR_SHARED
#define	LR_VGACOLOR	LR_VGACOLOR
#endif	/* not MS_WINCE */

// @pyswig |DeleteObject|Deletes a logical pen, brush, font, bitmap, region, or palette, freeing all system resources associated with the object. After the object is deleted, the specified handle is no longer valid.
BOOLAPI DeleteObject(HANDLE h); // @pyparm int|handle||handle to the object to delete.

// @pyswig int|ImageList_Add|Adds an image or images to an image list. 
// @rdesc Returns the index of the first new image if successful, or -1 otherwise. 
int ImageList_Add(HIMAGELIST himl, // @pyparm int|himl||Handle to the image list. 
                  HBITMAP hbmImage, // @pyparm int|hbmImage||Handle to the bitmap that contains the image or images. The number of images is inferred from the width of the bitmap. 
				  HBITMAP hbmMask); // @pyparm int|hbmMask||Handle to the bitmap that contains the mask. If no mask is used with the image list, this parameter is ignored


// @pyswig HIMAGELIST|ImageList_Create|Create an image list
HIMAGELIST ImageList_Create(int cx, int cy, UINT flags, int cInitial, int cGrow);


#define	ILC_COLOR	ILC_COLOR
#ifndef	MS_WINCE
#define	ILC_COLOR4	ILC_COLOR4
#define	ILC_COLOR8	ILC_COLOR8
#define	ILC_COLOR16	ILC_COLOR16
#define	ILC_COLOR24	ILC_COLOR24
#define	ILC_COLOR32	ILC_COLOR32
#endif	/* not MS_WINCE */
#define	ILC_COLORDDB	ILC_COLORDDB
#define	ILC_MASK	ILC_MASK

// @pyswig BOOL |ImageList_Destroy|Destroy an imagelist
BOOLAPI ImageList_Destroy(HIMAGELIST himl);

// @pyswig BOOL |ImageList_Draw|Draw an image on an HDC
BOOLAPI ImageList_Draw(HIMAGELIST himl,int i,HDC hdcDst, int x, int y, UINT fStyle);

#define	ILD_BLEND25	ILD_BLEND25
#define	ILD_FOCUS	ILD_FOCUS
#define	ILD_BLEND50	ILD_BLEND50
#define	ILD_SELECTED	ILD_SELECTED
#define	ILD_BLEND	ILD_BLEND
#define	ILD_MASK	ILD_MASK
#define	ILD_NORMAL	ILD_NORMAL
#define	ILD_TRANSPARENT	ILD_TRANSPARENT

// @pyswig HICON|ImageList_GetIcon|Extract an icon from an imagelist
HICON ImageList_GetIcon(HIMAGELIST himl, int i, UINT flag);

// @pyswig int|ImageList_GetImageCount|Return count of images in imagelist
int ImageList_GetImageCount(HIMAGELIST himl);

// @pyswig HANDLE|ImageList_LoadImage|Loads bitmaps, cursors or icons, creates imagelist
HIMAGELIST ImageList_LoadImage(HINSTANCE hInst, RESOURCE_ID name,
				 int cx, int cGrow, COLORREF crMask, UINT uType, UINT uFlags);

// @pyswig HANDLE|ImageList_LoadBitmap|Creates an image list from the specified bitmap resource.
HIMAGELIST ImageList_LoadBitmap(HINSTANCE hInst, TCHAR *name,
				 int cx, int cGrow, COLORREF crMask);

// @pyswig BOOL|ImageList_Remove|Remove an image from an imagelist
BOOLAPI ImageList_Remove(HIMAGELIST himl, int i);

// @pyswig BOOL|ImageList_Replace|Replace an image in an imagelist with a bitmap image
int ImageList_Replace(HIMAGELIST himl, int i, HBITMAP hbmImage, HBITMAP hbmMask);

// @pyswig BOOL|ImageList_ReplaceIcon|Replace an image in an imagelist with an icon image
int ImageList_ReplaceIcon(HIMAGELIST himl, int i, HICON hicon);

// @pyswig COLORREF|ImageList_SetBkColor|Set the background color for the imagelist
COLORREF ImageList_SetBkColor(HIMAGELIST himl,COLORREF clrbk);

#define	CLR_NONE	CLR_NONE



// @pyswig int|MessageBox|Displays a message box
// @pyparm int|parent||The parent window
// @pyparm string/<o PyUnicode>|text||The text for the message box
// @pyparm string/<o PyUnicode>|caption||The caption for the message box
// @pyparm int|flags||
int MessageBox(HWND parent, TCHAR *text, TCHAR *caption, DWORD flags);

// @pyswig |MessageBeep|Plays a waveform sound.
// @pyparm int|type||The type of the beep
BOOLAPI MessageBeep(UINT type);

// @pyswig int|CreateWindow|Creates a new window.
HWND CreateWindow( 
	STRING_OR_ATOM_CW lpClassName, // @pyparm int/string|className||
	TCHAR *INPUT_NULLOK, // @pyparm string|windowTitle||
	DWORD dwStyle, // @pyparm int|style||The style for the window.
	int x,  // @pyparm int|x||
	int y,  // @pyparm int|y||
	int nWidth, // @pyparm int|width||
	int nHeight, // @pyparm int|height||
	HWND hWndParent, // @pyparm int|parent||Handle to the parent window.
	HMENU hMenu, // @pyparm int|menu||Handle to the menu to use for this window.
	HINSTANCE hInstance, // @pyparm int|hinstance||
	NULL_ONLY null // @pyparm None|reserved||Must be None
);

// @pyswig |DestroyWindow|
// @pyparm int|hwnd||The handle to the window
BOOLAPI DestroyWindow(HWND hwnd);

// @pyswig int|EnableWindow|
BOOL EnableWindow(HWND hwnd, BOOL bEnable);

// @pyswig int|FindWindow|Retrieves a handle to the top-level window whose class name and window name match the specified strings.
HWND FindWindow( 
	STRING_OR_ATOM className, // @pyparm int/string|className||
	TCHAR *INPUT_NULLOK); // @pyparm string|WindowName||

#ifndef	MS_WINCE
	// @pyswig int|FindWindowEx|Retrieves a handle to the top-level window whose class name and window name match the specified strings.
HWND FindWindowEx(
	HWND parent, // @pyparm int|hwnd||
	HWND childAfter, // @pyparm int|childAfter||
	STRING_OR_ATOM className, // @pyparm int/string|className||
	TCHAR *INPUT_NULLOK); // @pyparm string|WindowName||
#endif	/* not MS_WINCE */

// @pyswig |HideCaret|
BOOLAPI HideCaret(HWND hWnd);

// @pyswig |SetCaretPos|
BOOLAPI SetCaretPos(
	int X,  // @pyparm int|x||horizontal position  
	int Y   // @pyparm int|y||vertical position
);

/*BOOLAPI GetCaretPos(
  POINT *lpPoint   // address of structure to receive coordinates
);*/

// @pyswig |ShowCaret|
BOOLAPI ShowCaret(HWND hWnd);

// @pyswig int|ShowWindow|
// @pyparm int|hwnd||The handle to the window
// @pyparm int|cmdShow||
BOOL ShowWindow(HWND hWndMain, int nCmdShow);

// @pyswig int|IsWindowVisible|Indicates if the window has the WS_VISIBLE style.
// @pyparm int|hwnd||The handle to the window
BOOL IsWindowVisible(HWND hwnd);

// @pyswig |SetFocus|Sets focus to the specified window.
// @pyparm int|hwnd||The handle to the window
BOOLAPI SetFocus(HWND hwnd);

// @pyswig |UpdateWindow|
// @pyparm int|hwnd||The handle to the window
BOOLAPI UpdateWindow(HWND hWnd);

// @pyswig |BringWindowToTop|
// @pyparm int|hwnd||The handle to the window
BOOLAPI BringWindowToTop(HWND hWnd);

// @pyswig HWND|SetActiveWindow|
// @pyparm int|hwnd||The handle to the window
HWND SetActiveWindow(HWND hWnd);

// @pyswig HWND|GetActiveWindow|
HWND GetActiveWindow();

// @pyswig HWND|SetForegroundWindow|
// @pyparm int|hwnd||The handle to the window
BOOLAPI SetForegroundWindow(HWND hWnd);

// @pyswig HWND|GetForegroundWindow|
HWND GetForegroundWindow();

// @pyswig (left, top, right, bottom)|GetClientRect|
// @pyparm int|hwnd||The handle to the window
BOOLAPI GetClientRect(HWND hWnd, RECT *OUTPUT);

// @pyswig HDC|GetDC|Gets the device context for the window.
// @pyparm int|hwnd||The handle to the window
HDC GetDC(  HWND hWnd );

#ifndef MS_WINCE
HINSTANCE GetModuleHandle(TCHAR *INPUT_NULLOK);
#endif

// @pyswig (left, top, right, bottom)|GetWindowRect|
// @pyparm int|hwnd||The handle to the window
BOOLAPI GetWindowRect(HWND hWnd, RECT *OUTPUT);

// @pyswig int|GetStockObject|
HANDLE GetStockObject(int object);

// @pyswig |PostQuitMessage|
// @pyparm int|rc||
void PostQuitMessage(int rc);

#ifndef	MS_WINCE
// @pyswig |WaitMessage|Waits for a message
BOOLAPI WaitMessage();
#endif	/* MS_WINCE */

// @pyswig int|SetWindowPos|
BOOL SetWindowPos(  HWND hWnd,             // handle to window
  HWND hWndInsertAfter,  // placement-order handle
  int X,                 // horizontal position
  int Y,                 // vertical position  
  int cx,                // width
  int cy,                // height
  UINT uFlags            // window-positioning flags
);
  
%{
// @pyswig int|RegisterClass|Registers a window class.
static PyObject *PyRegisterClass(PyObject *self, PyObject *args)
{
	PyObject *obwc;
	// @pyparm <o PyWNDCLASS>|wndClass||An object describing the window class.
	if (!PyArg_ParseTuple(args, "O", &obwc))
		return NULL;
	if (!PyWNDCLASS_Check(obwc)) {
		PyErr_SetString(PyExc_TypeError, "The object must be a WNDCLASS object");
		return NULL;
	}
	ATOM at = RegisterClass( &((PyWNDCLASS *)obwc)->m_WNDCLASS );
	if (at==0)
		return PyWin_SetAPIError("RegisterClass");
	// Save the atom in a global dictionary.
	if (g_AtomMap==NULL)
		g_AtomMap = PyDict_New();

	PyObject *key = PyInt_FromLong(at);
	PyDict_SetItem(g_AtomMap, key, obwc);
	return key;
}
%}
%native (RegisterClass) PyRegisterClass;

%{
// @pyswig |UnregisterClass|
static PyObject *PyUnregisterClass(PyObject *self, PyObject *args)
{
	long atom, hinst;
	// @pyparm int|atom||The atom identifying the class previously registered.
	// @pyparm int|hinst||The handle to the instance unregistering the class.
	if (!PyArg_ParseTuple(args, "ll", &atom, &hinst))
		return NULL;

	if (!UnregisterClass((LPCTSTR)atom, (HINSTANCE)hinst))
		return PyWin_SetAPIError("UnregisterClass");

	// Delete the atom from the global dictionary.
	if (g_AtomMap) {
		PyObject *key = PyInt_FromLong(atom);
		PyDict_DelItem(g_AtomMap, key);
		Py_DECREF(key);
	}
	Py_INCREF(Py_None);
	return Py_None;
}
%}
%native (UnregisterClass) PyUnregisterClass;

%{
// @pyswig |PumpMessages|Runs a message loop until a WM_QUIT message is received.
// @rdesc Returns exit code from PostQuitMessage when a WM_QUIT message is received
static PyObject *PyPumpMessages(PyObject *self, PyObject *args)
{
	if (!PyArg_ParseTuple(args, ""))
		return NULL;

	MSG msg;
	int rc;

    Py_BEGIN_ALLOW_THREADS
	while ((rc=GetMessage(&msg, 0, 0, 0))==1) {
		if(NULL == hDialogCurrent || !IsDialogMessage(hDialogCurrent,&msg)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}
    Py_END_ALLOW_THREADS

	if (-1 == rc)
		return PyWin_SetAPIError("GetMessage");

	return PyInt_FromLong(msg.wParam);

	// @xref <om win32gui.PumpWaitingMessages>
}

// @pyswig int|PumpWaitingMessages|Pumps all waiting messages for the current thread.
// @rdesc Returns non-zero (exit code from PostQuitMessage) if a WM_QUIT message was received, else 0
static PyObject *PyPumpWaitingMessages(PyObject *self, PyObject *args)
{
	UINT firstMsg = 0, lastMsg = 0;
	if (!PyArg_ParseTuple (args, "|ii:PumpWaitingMessages", &firstMsg, &lastMsg))
		return NULL;
	// @pyseeapi PeekMessage and DispatchMessage

    MSG msg;
	long result = 0;
	// Read all of the messages in this next loop, 
	// removing each message as we read it.
	Py_BEGIN_ALLOW_THREADS
	while (PeekMessage(&msg, NULL, firstMsg, lastMsg, PM_REMOVE)) {
		// If it's a quit message, we're out of here.
		if (msg.message == WM_QUIT) {
			if(0 != msg.wParam)
				result = msg.wParam;
			else
				result = 1;
			break;
		}
		// Otherwise, dispatch the message.
		if(NULL == hDialogCurrent || !IsDialogMessage(hDialogCurrent,&msg)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	} // End of PeekMessage while loop
	// @xref <om win32gui.PumpMessages>
	Py_END_ALLOW_THREADS
	return PyInt_FromLong(result);
}

%}
%native (PumpMessages) PyPumpMessages;
%native (PumpWaitingMessages) PyPumpWaitingMessages;

// @pyswig int|TranslateMessage|
// @pyparm MSG|msg||
BOOL TranslateMessage(MSG *INPUT);

// @pyswig int|DispatchMessage|
// @pyparm MSG|msg||
LRESULT DispatchMessage(MSG *INPUT);

// @pyswig int|TranslateAccelerator|
int TranslateAccelerator(
    HWND hwnd, // @pyparm int|hwnd||
    HACCEL haccel, // @pyparm int|haccel||
    MSG *INPUT // @pyparm MSG|msg||
);

// DELETE ME!
%{
static PyObject *Unicode(PyObject *self, PyObject *args)
{
	char *text;
#if PY_VERSION_HEX > 0x2030300
	PyErr_Warn(PyExc_PendingDeprecationWarning, "win32gui.Unicode will die!");
#endif
	if (!PyArg_ParseTuple(args, "s", &text))
		return NULL;
	return PyUnicodeObject_FromString(text);
}
%}
%native (Unicode) Unicode;

%{
static PyObject *
PyHIWORD(PyObject *self, PyObject *args)
{	int n;
	if(!PyArg_ParseTuple(args, "i:HIWORD", &n))
		return NULL;
	return PyInt_FromLong(HIWORD(n));
}
%}
%native (HIWORD) PyHIWORD;

%{
static PyObject *
PyLOWORD(PyObject *self, PyObject *args)
{	int n;
	if(!PyArg_ParseTuple(args, "i:LOWORD", &n))
		return NULL;
	return PyInt_FromLong(LOWORD(n));
}
%}
%native (LOWORD) PyLOWORD;

// Should go in win32sh?
%{
BOOL PyObject_AsNOTIFYICONDATA(PyObject *ob, NOTIFYICONDATA *pnid)
{
	PyObject *obTip=NULL;
	memset(pnid, 0, sizeof(*pnid));
	pnid->cbSize = sizeof(*pnid);
	if (!PyArg_ParseTuple(ob, "l|iiilO:NOTIFYICONDATA tuple", &pnid->hWnd, &pnid->uID, &pnid->uFlags, &pnid->uCallbackMessage, &pnid->hIcon, &obTip))
		return FALSE;
	if (obTip) {
		TCHAR *szTip;
		if (!PyWinObject_AsTCHAR(obTip, &szTip))
			return NULL;
		_tcsncpy(pnid->szTip, szTip, sizeof(pnid->szTip)/sizeof(TCHAR));
		PyWinObject_FreeTCHAR(szTip);
	}
	return TRUE;
}
%}
#define NIF_ICON NIF_ICON
#define NIF_MESSAGE NIF_MESSAGE
#define NIF_TIP NIF_TIP
#define NIM_ADD NIM_ADD // Adds an icon to the status area. 
#define NIM_DELETE  NIM_DELETE // Deletes an icon from the status area. 
#define NIM_MODIFY  NIM_MODIFY // Modifies an icon in the status area.  
#ifdef NIM_SETFOCUS
#define NIM_SETFOCUS NIM_SETFOCUS // Give the icon focus.  
#endif

%typemap(python,in) NOTIFYICONDATA *{
	if (!PyObject_AsNOTIFYICONDATA($source, $target))
		return NULL;
}
%typemap(python,arginit) NOTIFYICONDATA *{
	NOTIFYICONDATA nid;
	$target = &nid;
}
// @pyswig |Shell_NotifyIcon|Adds, removes or modifies a taskbar icon,
BOOLAPI Shell_NotifyIcon(DWORD dwMessage, NOTIFYICONDATA *pnid);

#ifdef MS_WINCE
HWND    CommandBar_Create(HINSTANCE hInst, HWND hwndParent, int idCmdBar);

BOOLAPI CommandBar_Show(HWND hwndCB, BOOL fShow);

int     CommandBar_AddBitmap(HWND hwndCB, HINSTANCE hInst, int idBitmap,
								  int iNumImages, int iImageWidth,
								  int iImageHeight);

HWND    CommandBar_InsertComboBox(HWND hwndCB, HINSTANCE hInstance,
									   int  iWidth, UINT dwStyle,
									   WORD idComboBox, WORD iButton);

BOOLAPI CommandBar_InsertMenubar(HWND hwndCB, HINSTANCE hInst,
									  WORD idMenu, WORD iButton);

BOOLAPI CommandBar_InsertMenubarEx(HWND hwndCB,
						               HINSTANCE hinst,
						               TCHAR *pszMenu,
						               WORD iButton);

BOOLAPI CommandBar_DrawMenuBar(HWND hwndCB,
		                       WORD iButton);

HMENU   CommandBar_GetMenu(HWND hwndCB, WORD iButton);

BOOLAPI CommandBar_AddAdornments(HWND hwndCB,
								 DWORD dwFlags,
								 DWORD dwReserved);

int     CommandBar_Height(HWND hwndCB);

/////////////////////////////////////////////////////////
//
// Edit control stuff!
#endif

// A hack that needs to be replaced with a general buffer inteface.
%{
static PyObject *PyEdit_GetLine(PyObject *self, PyObject *args)
{
	long hwnd;
	int line, size=0;
	if (!PyArg_ParseTuple(args, "li|i", &hwnd, &line, &size))
		return NULL;
	int numChars;
	TCHAR *buf;
	Py_BEGIN_ALLOW_THREADS
	if (size==0)
		size = Edit_LineLength((HWND)hwnd, line)+1;
	buf = (TCHAR *)malloc(size * sizeof(TCHAR));
	numChars = Edit_GetLine((HWND)hwnd, line, buf, size);
	Py_END_ALLOW_THREADS
	PyObject *ret;
	if (numChars==0) {
		Py_INCREF(Py_None);
		ret = Py_None;
	} else
		ret = PyWinObject_FromTCHAR(buf, numChars);
	free(buf);
	return ret;
}
%}
%native (Edit_GetLine) PyEdit_GetLine;


#ifdef MS_WINCE
%{
// Where oh where has this function gone, oh where oh where can it be?
//#include "dbgapi.h"
static PyObject *PyNKDbgPrintfW(PyObject *self, PyObject *args)
{
	PyObject *obtext;
	if (!PyArg_ParseTuple(args, "O", &obtext))
		return NULL;
	TCHAR *text;
	if (!PyWinObject_AsTCHAR(obtext, &text))
		return NULL;
//	NKDbgPrintfW(_T("%s"), text);
	PyWinObject_FreeTCHAR(text);
	Py_INCREF(Py_None);
	return Py_None;
}
%}
%native (NKDbgPrintfW) PyNKDbgPrintfW;
#endif

// DAVID ASCHER DAA

// Need to complete the documentation!

// @pyswig int|GetSystemMenu|
// @pyparm int|hwnd||The handle to the window
// @pyparm int|bRevert||
// @rdesc The result is a HMENU to the menu.
HMENU GetSystemMenu(HWND hWnd, BOOL bRevert); 

// @pyswig |DrawMenuBar|
// @pyparm int|hwnd||The handle to the window
BOOLAPI DrawMenuBar(HWND hWnd);

// @pyswig |MoveWindow|
BOOLAPI MoveWindow(HWND hWnd, int X, int Y, int nWidth, int nHeight, BOOL bRepaint);
// @pyparm int|hwnd||The handle to the window
// @pyparm int|x||
// @pyparm int|y||
// @pyparm int|width||
// @pyparm int|height||
// @pyparm int|bRepaint||
#ifndef MS_WINCE
// @pyswig |CloseWindow|
BOOLAPI CloseWindow(HWND hWnd);
#endif

// @pyswig |DeleteMenu|
// @pyparm int|hmenu||The handle to the menu
// @pyparm int|position||The position to delete.
// @pyparm int|flags||
BOOLAPI DeleteMenu(HMENU hMenu, UINT uPosition, UINT uFlags);

// @pyswig |RemoveMenu|
// @pyparm int|hmenu||The handle to the menu
// @pyparm int|position||The position to delete.
// @pyparm int|flags||
BOOLAPI RemoveMenu(HMENU hMenu, UINT uPosition, UINT uFlags);

// @pyswig int|CreateMenu|
// @rdesc The result is a HMENU to the new menu.
HMENU CreateMenu();
// @pyswig int|CreatePopupMenu|
// @rdesc The result is a HMENU to the new menu.
HMENU CreatePopupMenu(); 


// @pyswig int|TrackPopupMenu|Display popup shortcut menu
// @pyparm int|hmenu||The handle to the menu
// @pyparm uint|flags||flags
// @pyparm int|x||x pos
// @pyparm int|y||y pos
// @pyparm int|reserved||reserved
// @pyparm hwnd|hwnd||owner window
// @pyparm REC|prcRect||Pointer to rec (can be None)

LRESULT TrackPopupMenu(HMENU hmenu, UINT flags, int x, int y, int reserved, HWND hwnd, const RECT *INPUT_NULLOK);

#define	TPM_CENTERALIGN	TPM_CENTERALIGN
#define	TPM_LEFTALIGN	TPM_LEFTALIGN
#define	TPM_RIGHTALIGN	TPM_RIGHTALIGN
#define	TPM_BOTTOMALIGN	TPM_BOTTOMALIGN
#define	TPM_TOPALIGN	TPM_TOPALIGN
#define	TPM_VCENTERALIGN	TPM_VCENTERALIGN
#define	TPM_NONOTIFY	TPM_NONOTIFY
#define	TPM_RETURNCMD	TPM_RETURNCMD
#ifndef	MS_WINCE
#define	TPM_LEFTBUTTON	TPM_LEFTBUTTON
#define	TPM_RIGHTBUTTON	TPM_RIGHTBUTTON
#endif	/* not MS_WINCE */

%{
#include "commdlg.h"

PyObject *Pylpstr(PyObject *self, PyObject *args) {
	long address;
	PyArg_ParseTuple(args, "l", &address);
	return PyString_FromString((char *)address);
}

%}
%native (lpstr) Pylpstr;

// @pyswig int|CommDlgExtendedError|
DWORD CommDlgExtendedError(void);

%typemap (python, in) OPENFILENAME *INPUT (int size){
	size = sizeof(OPENFILENAME);
/*	$source = PyObject_Str($source); */
	if ( (! PyString_Check($source)) || (size != PyString_GET_SIZE($source)) ) {
		PyErr_Format(PyExc_TypeError, "Argument must be a %d-byte string", size);
		return NULL;
	}
	$target = ( OPENFILENAME *)PyString_AS_STRING($source);
}

#ifndef	MS_WINCE
// @pyswig int|ExtractIcon|
// @pyparm int|hinstance||
// @pyparm string/<o PyUnicode>|moduleName||
// @pyparm int|index||
// @comm You must destroy the icon handle returned by calling the <om win32gui.DestroyIcon> function. 
// @rdesc The result is a HICON.
HICON ExtractIcon(HINSTANCE hinst, TCHAR *modName, UINT index);

// @pyswig int|ExtractIconEx|
// @pyparm string|moduleName||
// @pyparm int|index||
// @pyparm int|numIcons|1|
// @comm You must destroy each icon handle returned by calling the <om win32gui.DestroyIcon> function. 
// @rdesc If index==-1, the result is an integer with the number of icons in
// the file, otherwise it is 2 arrays of icon handles.
%{
static PyObject *PyExtractIconEx(PyObject *self, PyObject *args)
{
    int i;
	char *fname;
    int index, nicons=1, nicons_got;
	if (!PyArg_ParseTuple(args, "si|i", &fname, &index, &nicons))
		return NULL;
    if (index==-1) {
        nicons = ExtractIconEx(fname, index, NULL, NULL, 0);
        return PyInt_FromLong(nicons);
    }
    if (nicons<=0)
        return PyErr_Format(PyExc_ValueError, "Must supply a valid number of icons to fetch.");
    HICON *rgLarge = NULL;
    HICON *rgSmall = NULL;
    PyObject *ret = NULL;
    PyObject *objects_large = NULL;
    PyObject *objects_small = NULL;
    rgLarge = (HICON *)calloc(nicons, sizeof(HICON));
    if (rgLarge==NULL) {
        PyErr_NoMemory();
        goto done;
    }
    rgSmall = (HICON *)calloc(nicons, sizeof(HICON));
    if (rgSmall==NULL) {
        PyErr_NoMemory();
        goto done;
    }
    nicons_got = ExtractIconEx(fname, index, rgLarge, rgSmall, nicons);
    if (nicons_got==-1) {
        PyWin_SetAPIError("ExtractIconEx");
        goto done;
    }
    // Asking for 1 always says it got 2!?
    nicons = min(nicons, nicons_got);
    objects_large = PyList_New(nicons);
    if (!objects_large) goto done;
    objects_small = PyList_New(nicons);
    if (!objects_small) goto done;
    for (i=0;i<nicons;i++) {
        PyList_SET_ITEM(objects_large, i, PyInt_FromLong((long)rgLarge[i]));
        PyList_SET_ITEM(objects_small, i, PyInt_FromLong((long)rgSmall[i]));
    }
    ret = Py_BuildValue("OO", objects_large, objects_small);
done:
    Py_XDECREF(objects_large);
    Py_XDECREF(objects_small);
    if (rgLarge) free(rgLarge);
    if (rgSmall) free(rgSmall);
    return ret;
}
%}
%native (ExtractIconEx) PyExtractIconEx;
#endif	/* not MS_WINCE */

// @pyswig |DestroyIcon|
// @pyparm int|hicon||The icon to destroy.
BOOLAPI DestroyIcon( HICON hicon);


// @pyswig |ScreenToClient|Convert screen coordinates to client coords
BOOLAPI ScreenToClient(HWND hWnd,POINT *BOTH);

// @pyswig |ClientToScreen|Convert client coordinates to screen coords
BOOLAPI ClientToScreen(HWND hWnd,POINT *BOTH);

// @pyswig int|GetOpenFileName|Creates an Open dialog box that lets the user specify the drive, directory, and the name of a file or set of files to open.
// @rdesc If the user presses OK, the function returns TRUE.  Otherwise, use CommDlgExtendedError for error details.

BOOL GetOpenFileName(OPENFILENAME *INPUT);

#ifndef MS_WINCE

%typemap (python, in) MENUITEMINFO *INPUT (int target_size){
	if (0 != PyObject_AsReadBuffer($source, (const void **)&$target, &target_size))
		return NULL;
	if (sizeof MENUITEMINFO != target_size)
		return PyErr_Format(PyExc_TypeError, "Argument must be a %d-byte string/buffer (got %d bytes)", sizeof MENUITEMINFO, target_size);
}

%typemap (python,in) MENUITEMINFO *BOTH(int target_size) {
	if (0 != PyObject_AsWriteBuffer($source, (void **)&$target, &target_size))
		return NULL;
	if (sizeof MENUITEMINFO != target_size)
		return PyErr_Format(PyExc_TypeError, "Argument must be a %d-byte buffer (got %d bytes)", sizeof MENUITEMINFO, target_size);
}

// @pyswig |InsertMenuItem|Inserts a menu item
// @pyparm int|hMenu||
// @pyparm int|fByPosition||
// @pyparm buffer|menuItem||A string or buffer in the format of a MENUITEMINFO structure.
BOOLAPI InsertMenuItem(HMENU hMenu, UINT uItem, BOOL fByPosition, MENUITEMINFO *INPUT);

// @pyswig |SetMenuItemInfo|Sets menu information
// @pyparm int|hMenu||
// @pyparm int|fByPosition||
// @pyparm buffer|menuItem||A string or buffer in the format of a MENUITEMINFO structure.
BOOLAPI SetMenuItemInfo(HMENU hMenu, UINT uItem, BOOL fByPosition, MENUITEMINFO *INPUT);

// @pyswig |GetMenuItemInfo|Gets menu information
// @pyparm int|hMenu||
// @pyparm int|fByPosition||
// @pyparm buffer|menuItem||A string or buffer in the format of a MENUITEMINFO structure.
BOOLAPI GetMenuItemInfo(HMENU hMenu, UINT uItem, BOOL fByPosition, MENUITEMINFO *BOTH);

#endif

#ifndef	MS_WINCE
// @pyswig int|GetMenuItemCount|
int GetMenuItemCount(HMENU hMenu);

// @pyswig int|GetMenuItemRect|
int GetMenuItemRect(HWND hWnd, HMENU hMenu, UINT uItem, RECT *OUTPUT);

// @pyswig int|GetMenuState|
int GetMenuState(HMENU hMenu, UINT uID, UINT flags);

// @pyswig |SetMenuDefaultItem|
BOOLAPI SetMenuDefaultItem(HMENU hMenu, UINT flags, UINT fByPos);
#endif	/* not MS_WINCE */

// @pyswig |AppendMenu|
BOOLAPI AppendMenu(HMENU hMenu, UINT uFlags, UINT uIDNewItem, TCHAR *lpNewItem);

// @pyswig |InsertMenu|
BOOLAPI InsertMenu(HMENU hMenu, UINT uPosition, UINT uFlags, UINT uIDNewItem, TCHAR *INPUT_NULLOK);

// @pyswig |EnableMenuItem|
BOOLAPI EnableMenuItem(HMENU hMenu, UINT uIDEnableItem, UINT uEnable);

// @pyswig int|CheckMenuItem|
int CheckMenuItem(HMENU hMenu, UINT uIDCheckItem, UINT uCheck);

#ifndef	MS_WINCE
// @pyswig |ModifyMenu|Changes an existing menu item. This function is used to specify the content, appearance, and behavior of the menu item.
BOOLAPI ModifyMenu(
  HMENU hMnu, // @pyparm int|hMnu||handle to menu
  UINT uPosition, // @pyparm int|uPosition||menu item to modify
  UINT uFlags,          // @pyparm int|uFlags||options
  UINT uIDNewItem,  // @pyparm int|uIDNewItem||identifier, menu, or submenu
  LPCTSTR lpNewItem     // @pyparm string|newItem||menu item content
);

// @pyswig int|GetMenuItemID|Retrieves the menu item identifier of a menu item located at the specified position in a menu. 
UINT GetMenuItemID(
  HMENU hMenu,  // @pyparm int|hMenu||handle to menu
  int nPos      // @pyparm int|nPos||position of menu item
 );

// @pyswig |SetMenuItemBitmaps|Associates the specified bitmap with a menu item. Whether the menu item is selected or clear, the system displays the appropriate bitmap next to the menu item.
BOOLAPI SetMenuItemBitmaps(
  HMENU hMenu,               // @pyparm int|hMenu||handle to menu
  UINT uPosition,            // @pyparm int|uPosition||menu item
  UINT uFlags,               // @pyparm int|uFlags||options
  HBITMAP hBitmapUnchecked,  // @pyparm int|hBitmapUnchecked||handle to unchecked bitmap
  HBITMAP hBitmapChecked     // @pyparm int|hBitmapChecked||handle to checked bitmap
);
#endif	/* not MS_WINCE */

// @pyswig |CheckMenuRadioItem|Checks a specified menu item and makes it a
// radio item. At the same time, the function clears all other menu items in
// the associated group and clears the radio-item type flag for those items.
BOOLAPI CheckMenuRadioItem(
  HMENU hMenu,               // @pyparm int|hMenu||handle to menu
  UINT idFirst,  // @pyparm int|idFirst||identifier or position of first item
  UINT idLast,  // @pyparm int|idLast||identifier or position of last item
  UINT idCheck,  // @pyparm int|idCheck||identifier or position of item to check
  UINT uFlags               // @pyparm int|uFlags||options
);


BOOLAPI DrawFocusRect(HDC hDC,  RECT *INPUT);
#ifndef	MS_WINCE
int DrawText(HDC hDC, LPCTSTR lpString, int nCount, RECT *INPUT, UINT uFormat);
#endif	/* not MS_WINCE */
BOOLAPI DrawEdge(HDC hdc, RECT *INPUT, UINT edge, UINT grfFlags); 
int FillRect(HDC hDC,   RECT *INPUT, HBRUSH hbr);
DWORD GetSysColor(int nIndex);
BOOLAPI InvalidateRect(HWND hWnd,  RECT *INPUT_NULLOK , BOOL bErase);
#ifndef	MS_WINCE
int FrameRect(HDC hDC,   RECT *INPUT, HBRUSH hbr);
#endif	/* not MS_WINCE */
int GetUpdateRgn(HWND hWnd, HRGN hRgn, BOOL bErase);
/*
HDC BeginPaint(HWND hwnd, LPPAINTSTRUCT lpPaint);
BOOLAPI EndPaint(HWND hWnd,  PAINTSTRUCT *lpPaint); 
*/

// @pyswig int|CreateWindowEx|Creates a new window with Extended Style.
HWND CreateWindowEx( 
	DWORD dwExStyle,      // @pyparm int|dwExStyle||extended window style
	STRING_OR_ATOM_CW lpClassName, // @pyparm int/string|className||
	TCHAR *INPUT_NULLOK, // @pyparm string|windowTitle||
	DWORD dwStyle, // @pyparm int|style||The style for the window.
	int x,  // @pyparm int|x||
	int y,  // @pyparm int|y||
	int nWidth, // @pyparm int|width||
	int nHeight, // @pyparm int|height||
	HWND hWndParent, // @pyparm int|parent||Handle to the parent window.
	HMENU hMenu, // @pyparm int|menu||Handle to the menu to use for this window.
	HINSTANCE hInstance, // @pyparm int|hinstance||
	NULL_ONLY null // @pyparm None|reserved||Must be None
);

// @pyswig int|GetParent|Retrieves a handle to the specified child window's parent window.
HWND GetParent(
	HWND hWnd // @pyparm int|child||handle to child window
); 

// @pyswig int|SetParent|changes the parent window of the specified child window. 
HWND SetParent(
	HWND hWndChild, // @pyparm int|child||handle to window whose parent is changing
	HWND hWndNewParent // @pyparm int|child||handle to new parent window
); 

// @pyswig |GetCursorPos|retrieves the cursor's position, in screen coordinates. 
BOOLAPI GetCursorPos(
  POINT *OUTPUT   // @pyparm int, int|point||address of structure for cursor position
);
 
// @pyswig int|GetDesktopWindow|returns the desktop window 
HWND GetDesktopWindow();

// @pyswig int|GetWindow|returns a window that has the specified relationship (Z order or owner) to the specified window.  
HWND GetWindow(
	HWND hWnd,  // @pyparm int|hWnd||handle to original window
	UINT uCmd   // @pyparm int|uCmd||relationship flag
);
// @pyswig int|GetWindowDC|returns the device context (DC) for the entire window, including title bar, menus, and scroll bars.
HDC GetWindowDC(
	HWND hWnd   // @pyparm int|hWnd||handle of window
); 

#ifndef	MS_WINCE
// @pyswig |IsIconic|determines whether the specified window is minimized (iconic).
BOOL IsIconic(  HWND hWnd   // @pyparm int|hWnd||handle to window
); 
#endif	/* not MS_WINCE */


// @pyswig |IsWindow|determines whether the specified window handle identifies an existing window.
BOOL IsWindow(  HWND hWnd   // @pyparm int|hWnd||handle to window
); 

// @pyswig |IsChild|Tests whether a window is a child window or descendant window of a specified parent window
BOOL IsChild(  
	HWND hWndParent,   // @pyparm int|hWndParent||handle to parent window
	HWND hWnd   // @pyparm int|hWnd||handle to window to test
); 

// @pyswig |ReleaseCapture|Releases the moust capture for a window.
BOOLAPI ReleaseCapture();
// @pyswig int|GetCapture|Returns the window with the mouse capture.
HWND GetCapture();
// @pyswig |SetCapture|Captures the mouse for the specified window.
BOOLAPI SetCapture(HWND hWnd);

// @pyswig int|ReleaseDC|Releases a device context.
int ReleaseDC(
	HWND hWnd,  // @pyparm int|hWnd||handle to window
	HDC hDC     // @pyparm int|hDC||handle to device context
); 

//  |SystemParametersInfo|queries or sets system-wide parameters. This function can also update the user profile while setting a parameter. 
/**
BOOLAPI SystemParametersInfo(  
	UINT uiAction, // @pyparm int|uiAction||system parameter to query or set
	UINT uiParam,  // @pyparm int|uiParam||depends on action to be taken
	PVOID pvParam, // @pyparm int|pvParam||depends on action to be taken
	UINT fWinIni   // @pyparm int|fWinIni||user profile update flag
	);
**/

// @pyswig |CreateCaret|
BOOLAPI CreateCaret(
	HWND hWnd,        // @pyparm int|hWnd||handle to owner window
	HBITMAP hBitmap,  // @pyparm int|hBitmap||handle to bitmap for caret shape
	int nWidth,       // @pyparm int|nWidth||caret width
	int nHeight       // @pyparm int|nHeight||caret height
); 

// @pyswig |DestroyCaret|
BOOLAPI DestroyCaret();

// @pyswig int|ScrollWindowEx|scrolls the content of the specified window's client area. 
int ScrollWindowEx(
	HWND hWnd,        // @pyparm int|hWnd||handle to window to scroll
	int dx,           // @pyparm int|dx||amount of horizontal scrolling
	int dy,           // @pyparm int|dy||amount of vertical scrolling
	RECT *INPUT_NULLOK, // @pyparm int|prcScroll||address of structure with scroll rectangle
	RECT *INPUT_NULLOK,  // @pyparm int|prcClip||address of structure with clip rectangle
	struct HRGN__ *NONE_ONLY,  // @pyparm int|hrgnUpdate||handle to update region
	RECT *INPUT_NULLOK, // @pyparm int|prcUpdate||address of structure for update rectangle
	UINT flags        // @pyparm int|flags||scrolling flags
); 

// Get/SetScrollInfo

%{

#define GUI_BGN_SAVE PyThreadState *_save = PyEval_SaveThread()
#define GUI_END_SAVE PyEval_RestoreThread(_save)
#define GUI_BLOCK_THREADS Py_BLOCK_THREADS
#define RETURN_NONE				do {Py_INCREF(Py_None);return Py_None;} while (0)
#define RETURN_ERR(err)			do {PyErr_SetString(ui_module_error,err);return NULL;} while (0)
#define RETURN_MEM_ERR(err)		do {PyErr_SetString(PyExc_MemoryError,err);return NULL;} while (0)
#define RETURN_TYPE_ERR(err)	do {PyErr_SetString(PyExc_TypeError,err);return NULL;} while (0)
#define RETURN_VALUE_ERR(err)	do {PyErr_SetString(PyExc_ValueError,err);return NULL;} while (0)
#define RETURN_API_ERR(fn) return ReturnAPIError(fn)

#define CHECK_NO_ARGS(args)		do {if (!PyArg_ParseTuple(args,"")) return NULL;} while (0)
#define CHECK_NO_ARGS2(args, fnName) do {if (!PyArg_ParseTuple(args,":"#fnName)) return NULL;} while (0)

// @object PySCROLLINFO|A tuple representing a SCROLLINFO structure
// @tupleitem 0|int|addnMask|Additional mask information.  Python automatically fills the mask for valid items, so currently the only valid values are zero, and win32con.SIF_DISABLENOSCROLL.
// @tupleitem 1|int|min|The minimum scrolling position.  Both min and max, or neither, must be provided.
// @tupleitem 2|int|max|The maximum scrolling position.  Both min and max, or neither, must be provided.
// @tupleitem 3|int|page|Specifies the page size. A scroll bar uses this value to determine the appropriate size of the proportional scroll box.
// @tupleitem 4|int|pos|Specifies the position of the scroll box.
// @tupleitem 5|int|trackPos|Specifies the immediate position of a scroll box that the user 
// is dragging. An application can retrieve this value while processing 
// the SB_THUMBTRACK notification message. An application cannot set 
// the immediate scroll position; the <om PyCWnd.SetScrollInfo> function ignores 
// this member.
// @comm When passed to Python, will always be a tuple of size 6, and items may be None if not available.
// @comm When passed from Python, it must have the addn mask attribute, but all other items may be None, or not exist.
BOOL ParseSCROLLINFOTuple( PyObject *args, SCROLLINFO *pInfo)
{
	PyObject *ob;
	int len = PyTuple_Size(args);
	if (len<1 || len > 5) {
		PyErr_SetString(PyExc_TypeError, "SCROLLINFO tuple has invalid size");
		return FALSE;
	}
	PyErr_Clear(); // clear any errors, so I can detect my own.
	// 0 - mask.
	if ((ob=PyTuple_GetItem(args, 0))==NULL)
		return FALSE;
	pInfo->fMask = (UINT)PyInt_AsLong(ob);
	// 1/2 - nMin/nMax
	if (len==2) {
		PyErr_SetString(PyExc_TypeError, "SCROLLINFO - Both min and max, or neither, must be provided.");
		return FALSE;
	}
	if (len<3) return TRUE;
	if ((ob=PyTuple_GetItem(args, 1))==NULL)
		return FALSE;
	if (ob != Py_None) {
		pInfo->fMask |= SIF_RANGE;
		pInfo->nMin = PyInt_AsLong(ob);
		if ((ob=PyTuple_GetItem(args, 2))==NULL)
			return FALSE;
		pInfo->nMax = PyInt_AsLong(ob);
	}
	// 3 == nPage.
	if (len<4) return TRUE;
	if ((ob=PyTuple_GetItem(args, 3))==NULL)
		return FALSE;
	if (ob != Py_None) {
		pInfo->fMask |=SIF_PAGE;
		pInfo->nPage = PyInt_AsLong(ob);
	}
	// 4 == nPos
	if (len<5) return TRUE;
	if ((ob=PyTuple_GetItem(args, 4))==NULL)
		return FALSE;
	if (ob != Py_None) {
		pInfo->fMask |=SIF_POS;
		pInfo->nPos = PyInt_AsLong(ob);
	}
	// 5 == trackpos
	if (len<6) return TRUE;
	if ((ob=PyTuple_GetItem(args, 5))==NULL)
		return FALSE;
	if (ob != Py_None) {
		pInfo->nTrackPos = PyInt_AsLong(ob);
	}
	return TRUE;
}

PyObject *MakeSCROLLINFOTuple(SCROLLINFO *pInfo)
{
	PyObject *ret = PyTuple_New(6);
	if (ret==NULL) return NULL;
	PyTuple_SET_ITEM(ret, 0, PyInt_FromLong(0));
	if (pInfo->fMask & SIF_RANGE) {
		PyTuple_SET_ITEM(ret, 1, PyInt_FromLong(pInfo->nMin));
		PyTuple_SET_ITEM(ret, 2, PyInt_FromLong(pInfo->nMax));
	} else {
		Py_INCREF(Py_None);
		Py_INCREF(Py_None);
		PyTuple_SET_ITEM(ret, 1, Py_None);
		PyTuple_SET_ITEM(ret, 2, Py_None);
	}
	if (pInfo->fMask & SIF_PAGE) {
		PyTuple_SET_ITEM(ret, 3, PyInt_FromLong(pInfo->nPage));
	} else {
		Py_INCREF(Py_None);
		PyTuple_SET_ITEM(ret, 3, Py_None);
	}
	if (pInfo->fMask & SIF_POS) {
		PyTuple_SET_ITEM(ret, 4, PyInt_FromLong(pInfo->nPos));
	} else {
		Py_INCREF(Py_None);
		PyTuple_SET_ITEM(ret, 4, Py_None);
	}
	PyTuple_SET_ITEM(ret, 5, PyInt_FromLong(pInfo->nTrackPos));
	return ret;
}

// @pyswig |SetScrollInfo|Sets information about a scroll-bar
// @rdesc  Returns an int with the current position of the scroll box.
static PyObject *PySetScrollInfo(PyObject *self, PyObject *args) {
	int nBar;
	HWND hwnd;
	BOOL bRedraw = TRUE;
	PyObject *obInfo;

	// @pyparm int|hwnd||The handle to the window.
	// @pyparm int|nBar||Identifies the bar.
	// @pyparm <o PySCROLLINFO>|scollInfo||Scollbar info.
	// @pyparm int|bRedraw|1|Should the bar be redrawn?
	if (!PyArg_ParseTuple(args, "liO|i:SetScrollInfo",
						  &hwnd, &nBar, &obInfo, &bRedraw)) {
		PyWin_SetAPIError("SetScrollInfo");
		return NULL;
	}
	SCROLLINFO info;
	info.cbSize = sizeof(SCROLLINFO);
	if (ParseSCROLLINFOTuple(obInfo, &info) == 0) {
		PyWin_SetAPIError("SetScrollInfo");
		return NULL;
	}
	GUI_BGN_SAVE;
	int rc = SetScrollInfo(hwnd, nBar, &info, bRedraw);
	GUI_END_SAVE;
	return PyInt_FromLong(rc);
}
%}
%native (SetScrollInfo) PySetScrollInfo;

%{
// @pyswig <o PySCROLLINFO>|GetScrollInfo|Returns information about a scroll bar
static PyObject *
PyGetScrollInfo (PyObject *self, PyObject *args)
{
	HWND hwnd;
	int nBar;
	UINT fMask = SIF_ALL;
	// @pyparm int|hwnd||The handle to the window.
	// @pyparm int|nBar||The scroll bar to examine.  Can be one of win32con.SB_CTL, win32con.SB_VERT or win32con.SB_HORZ
	// @pyparm int|mask|SIF_ALL|The mask for attributes to retrieve.
	if (!PyArg_ParseTuple(args, "li|i:GetScrollInfo", &hwnd, &nBar, &fMask))
		return NULL;
	SCROLLINFO info;
	info.cbSize = sizeof(SCROLLINFO);
	info.fMask = fMask;
	GUI_BGN_SAVE;
	BOOL ok = GetScrollInfo(hwnd, nBar, &info);
	GUI_END_SAVE;
	if (!ok) {
		PyWin_SetAPIError("GetScrollInfo");
		return NULL;
	}
	return MakeSCROLLINFOTuple(&info);
}
%}
%native (GetScrollInfo) PyGetScrollInfo;

%{
// @pyswig string|GetClassName|Retrieves the name of the class to which the specified window belongs. 
static PyObject *
PyGetClassName(PyObject *self, PyObject *args)
{
	HWND hwnd;
	WCHAR buf[256];
	// @pyparm int|hwnd||The handle to the window
	if (!PyArg_ParseTuple(args, "i:GetClassName", &hwnd))
		return NULL;
	// dont bother with lock - no callback possible.
	int nchars = GetClassNameW(hwnd, buf, sizeof buf/sizeof buf[0]);
	if (nchars==0)
		PyWin_SetAPIError("GetClassName");
	else
		WideCharToMultiByte(CP_ACP, 0, buf, -1, (char *)buf, nchars, NULL, 0);
	return PyString_FromStringAndSize((char *)buf, nchars);
}
%}
%native (GetClassName) PyGetClassName;

