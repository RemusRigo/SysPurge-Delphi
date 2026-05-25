unit libMessages;

interface

uses
   Windows;

const

   // ListView Hit Test codes
   LVHT_NOWHERE         = $0001;
   LVHT_ONITEMICON      = $0002;
   LVHT_ONITEMLABEL     = $0004;
   LVHT_ONITEMSTATEICON = $0008;
   LVHT_ABOVE           = $0010;
   LVHT_BELOW           = $0020;
   LVHT_TOLEFT          = $0040;
   LVHT_TORIGHT         = $0080;
   LVHT_ONITEM          = LVHT_ONITEMICON or LVHT_ONITEMLABEL or LVHT_ONITEMSTATEICON;

   // ListView Item Rect
   LVIR_BOUNDS        = 0;
   LVIR_ICON          = 1;
   LVIR_LABEL         = 2;
   LVIR_SELECTBOUNDS  = 3;

   // ListView Item Flag
   LVIF_TEXT          = $0001;
   LVIF_IMAGE         = $0002;
   LVIF_PARAM         = $0004;
   LVIF_STATE         = $0008;
   LVIF_INDENT        = $0010;
   LVIF_GROUPID       = $0100;
   LVIF_COLUMNS       = $0200;
   LVIF_NORECOMPUTE   = $0800;

   // ListView Item State
   LVIS_FOCUSED       = $0001;
   LVIS_SELECTED      = $0002;
   LVIS_CUT           = $0004;
   LVIS_DROPHILITED   = $0008;
   LVIS_OVERLAYMASK   = $0F00;
   LVIS_STATEIMAGEMASK= $F000;

   // ListView Messages
   LVM_FIRST                    = $1000; // First
   LVM_GETITEMCOUNT             = $1004; // Returns total item count
   LVM_GETITEM                  = $104B; // Gets item attributes
   LVM_SETITEM                  = $104C; // Sets item attributes
   LVM_INSERTITEM               = $104D; // Inserts a new item
   LVM_DELETEITEM               = $1008; // Deletes an item
   LVM_DELETEALLITEMS           = $1009; // Deletes all items
   LVM_GETITEMRECT              = $100E; // Gets item bounding rect
   LVM_GETNEXTITEM              = $100C; // Finds next item matching flags
   LVM_HITTEST                  = $1012; // Tests which item is at a point
   LVM_ENSUREVISIBLE            = $1013; // Scrolls item into view
   LVM_SCROLL                   = $1014; // Scrolls the list
   LVM_REDRAWITEMS              = $1015; // Invalidates a range of items
   LVM_ARRANGE                  = $1016; // Arranges icons
   LVM_GETEDITCONTROL           = $1018; // Gets the label-edit control
   LVM_DELETECOLUMN             = $101C; // Deletes a column
   LVM_GETCOLUMNWIDTH           = $101D; // Gets column width
   LVM_SETCOLUMNWIDTH           = $101E; // Sets column width
   LVM_GETHEADER                = $101F; // Gets the header control handle
   LVM_GETVIEWRECT              = $1022; // Gets the bounding rect of all items
   LVM_GETITEMSTATE             = $102C; // Gets item state bits
   LVM_SETITEMSTATE             = $102B; // Sets item state bits
   LVM_SETEXTENDEDLISTVIEWSTYLE = $1036; // Sets extended styles
   LVM_GETEXTENDEDLISTVIEWSTYLE = $1037; // Gets extended styles
   LVM_GETSUBITEMRECT           = $1038; // Gets subitem bounding rect
   LVM_GETSELECTEDCOUNT         = $1032; // Returns selected item count
   LVM_GETCOLUMN                = $105F; // Gets column attributes
   LVM_SETCOLUMN                = $1060; // Sets column attributes
   LVM_INSERTCOLUMN             = $1061; // Inserts a column
   LVM_GETITEMTEXT              = $1073; // Gets item/subitem text
   LVM_SETITEMTEXT              = $1074; // Sets item/subitem text
   LVM_EDITLABEL                = $1076; // Starts in-place label editing

   // ListView Notifications
   LVN_ITEMCHANGING      = -100; // Before an item attribute changes
   LVN_ITEMCHANGED       = -101; // After an item attribute changes
   LVN_INSERTITEM        = -102; // An item was inserted
   LVN_DELETEITEM        = -103; // An item was deleted
   LVN_DELETEALLITEMS    = -104; // All items were deleted
   LVN_COLUMNCLICK       = -108; // A column header was clicked
   LVN_BEGINDRAG         = -109; // Left-button drag started
   LVN_BEGINRDRAG        = -111; // Right-button drag started
   LVN_ITEMACTIVATE      = -114; // Item was activated (double-click/Enter)
   LVN_ODSTATECHANGED    = -115; // Range of owner-data items changed state
   LVN_HOTTRACK          = -121; // Mouse moved over an item
   LVN_KEYDOWN           = -155; // Key was pressed
   LVN_MARQUEEBEGIN      = -156; // Rubber-band selection started
   LVN_GETDISPINFO       = -177; // Control needs item text/image (callback)
   LVN_SETDISPINFO       = -178; // Item text was edited (callback)
   LVN_ODFINDITEM        = -179; // Owner-data search requested
   LVN_GETINFOTIP        = -158; // Tooltip text needed
   LVN_INCREMENTALSEARCH = -163; // Incremental keyboard search started

   // ListView Next Item flags
   LVNI_ALL           = 0;
   LVNI_FOCUSED       = 1;
   LVNI_SELECTED      = 2;
   LVNI_CUT           = 4;
   LVNI_DROPHILITED   = 8;
   LVNI_ABOVE         = 256;
   LVNI_BELOW         = 512;
   LVNI_TOLEFT        = 1024;
   LVNI_TORIGHT       = 2048;

   //----------------------------------------------------------------------------------------------
   // Menu Flags
   MF_STRING_U    = UINT($00000000);
   MF_SEPARATOR_U = UINT($00000800);

   //----------------------------------------------------------------------------------------------
   // SetWindowPos Flags

   SWP_NOSIZE     = UINT($0001);
   SWP_NOMOVE     = UINT($0002);
   SWP_NOACTIVATE = UINT($0010);
   SWP_SHOWWINDOW = UINT($0040);

   //----------------------------------------------------------------------------------------------
   // Window Message Constants

   // 0 to WM_USER - 1 :	Messages reserved for the Windows Operating System
   WM_CREATE          = $0001;
   WM_DESTROY         = $0002;
   WM_CLOSE           = $0010;
   WM_QUERYENDSESSION = $0011;
   WM_QUIT            = $0012;
   WM_ERASEBKGND      = $0014;
   WM_SETCURSOR       = $0020;
   WM_SETTEXT         = $000C;
   WM_GETTEXT         = $000D;
   WM_PAINT           = $000F;
   WM_KEYDOWN         = $0100;
   WM_KEYUP           = $0101;
   WM_CHAR            = $0102;
   WM_COMMAND         = $0111;
   WM_SYSCOMMAND      = $0112;
   WM_TIMER           = $0113;
   WM_MOUSEMOVE       = $0200;
   WM_LBUTTONDOWN     = $0201;
   WM_LBUTTONUP       = $0202;
   WM_RBUTTONUP       = $0205;

   // WM_USER to $7FFF :	Messages for use by private window classes
   WM_USER           = $0400;
   WM_TRAYICON       = WM_USER + 1;

   // $8000 to $BFFF :	   Messages for use by applications (WM_APP)

   // $C000 to $FFFF :     String-based messages registered at runtime with RegisterWindowMessage

  //-----------------------------------------------------------------------------------------------
  // Window Styles

   WS_BORDER       = $00800000;        // The window has a thin-line border
   WS_CAPTION      = $00C00000;        // The window has a title bar (includes WS_BORDER)
   WS_CHILD        = $40000000;        // The window is a child window. Cannot be used with WS_POPUP
   WS_CHILDWINDOW  = WS_CHILD;         // Alias for WS_CHILD
   WS_CLIPCHILDREN = $02000000;        // Excludes child windows from clipping regions
   WS_CLIPSIBLINGS = $04000000;        // Clips sibling windows during drawing operations
   WS_DISABLED     = $08000000;        // Disables the window
   WS_DLGFRAME     = $00400000;        // The window has a dialog-style frame
   WS_GROUP        = $00020000;        // The window is the first control in a group
   WS_HSCROLL      = $00100000;        // The window has a horizontal scroll bar
   WS_ICONIC       = $20000000;        // The window is initially minimized
   WS_MAXIMIZE     = $01000000;        // The window is initially maximized
   WS_MAXIMIZEBOX  = $00010000;        // The window has a maximize button
   WS_MINIMIZE     = $20000000;        // The window is initially minimized
   WS_MINIMIZEBOX  = $00020000;        // The window has a minimize button
   WS_OVERLAPPED   = $00000000;        // A standard overlapped window (default)
   WS_POPUP        = DWORD($80000000); // The window is a pop-up window. Cannot be used with WS_CHILD
   WS_SIZEBOX      = $00040000;        // The window has a sizing border
   WS_SYSMENU      = $00080000;        // The window has a system menu
   WS_TABSTOP      = $00010000;        // The control can receive keyboard focus via TAB
   WS_THICKFRAME   = WS_SIZEBOX;       // Alias for WS_SIZEBOX
   WS_TILED        = WS_OVERLAPPED;    // Alias for WS_OVERLAPPED
   WS_VISIBLE      = $10000000;        // The window is initially visible
   WS_VSCROLL      = $00200000;        // The window has a vertical scroll bar

   //----------------------------------------------------------------------------------------------
   // Window Styles Extended

   WS_EX_LEFT                = $00000000; // The window has generic left-aligned properties. This is the default
   WS_EX_LTRREADING          = $00000000; // The window text is displayed using left-to-right reading-order properties
   WS_EX_RIGHTSCROLLBAR      = $00000000; // The vertical scroll bar is to the right of the client area. This is the default
   WS_EX_DLGMODALFRAME       = $00000001; // The window has a double border
   WS_EX_NOPARENTNOTIFY      = $00000004; // The child window does not send the WM_PARENTNOTIFY message to its parent
   WS_EX_TOPMOST             = $00000008; // The window should be placed above all non-topmost windows
   WS_EX_ACCEPTFILES         = $00000010; // The window accepts drag-drop files
   WS_EX_TRANSPARENT         = $00000020; // The window should not be painted until siblings beneath it are painted
   WS_EX_WINDOWEDGE          = $0000003C; // The window has a border with a raised edge
   WS_EX_MDICHILD            = $00000040; // The window is a MDI child window
   WS_EX_TOOLWINDOW          = $00000080; // The window is intended to be used as a floating toolbar (no taskbar icon)
   WS_EX_CLIENTEDGE          = $00000200; // The window has a border with a sunken edge
   WS_EX_CONTEXTHELP         = $00000400; // The title bar includes a question mark. Cannot be used with maximize/minimize buttons
   WS_EX_RIGHT               = $00001000; // The window has generic "right-aligned" properties (RTL languages)
   WS_EX_RTLREADING          = $00002000; // The window text is displayed using right-to-left reading-order properties
   WS_EX_LEFTSCROLLBAR       = $00004000; // The vertical scroll bar is to the left of the client area (RTL languages)
   WS_EX_CONTROLPARENT       = $00010000; // The window itself contains child windows that should take part in dialog navigation
   WS_EX_STATICEDGE          = $00020000; // The window has a 3D border style for items that do not accept user input
   WS_EX_APPWINDOW           = $00040000; // Forces a top-level window onto the taskbar when the window is visible
   WS_EX_LAYERED             = $00080000; // The window is a layered window. Required for transparency/alpha effects
   WS_EX_NOINHERITLAYOUT     = $00100000; // The window does not pass its window layout to its child windows
   WS_EX_NOREDIRECTIONBITMAP = $00200000; // The window does not render to a redirection surface. Use for Acrylic/Composition
   WS_EX_LAYOUTRTL           = $00400000; // If the shell language is Hebrew/Arabic, the horizontal origin is on the right edge
   WS_EX_COMPOSITED          = $02000000; // Paints all descendants in bottom-to-top painting order using double-buffering
   WS_EX_NOACTIVATE          = $08000000; // A top-level window that does not become the foreground window when clicked
   // Combined styles
   WS_EX_OVERLAPPEDWINDOW = WS_EX_WINDOWEDGE or WS_EX_CLIENTEDGE;
   WS_EX_PALETTEWINDOW    = WS_EX_WINDOWEDGE or WS_EX_TOOLWINDOW or WS_EX_TOPMOST;


implementation

end.
