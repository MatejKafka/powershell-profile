using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace FileManagerDirectory {
	public class Win32Window {
		public class Window {
			public string Title {get; set;}
			public int Handle {get; set;}
			public int ProcessId {get; set;}
		}

		[DllImport("User32.dll")]
		[return: MarshalAs(UnmanagedType.Bool)]
		private static extern bool EnumWindows(CallBackPtr lpEnumFunc, IntPtr param);
		private delegate bool CallBackPtr(IntPtr hWnd, IntPtr param);

		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

		[DllImport("User32.dll")]
		private static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);

		[DllImport("user32.dll")]
		[return: MarshalAs(UnmanagedType.Bool)]
		private static extern bool IsWindowVisible(IntPtr hWnd);

		public static List<Window> GetWindows() {
			var windowList = new List<Window>();
			EnumWindows(Callback, IntPtr.Zero);
			return windowList;

			bool Callback(IntPtr hWnd, IntPtr param) {
				if (IsWindowVisible(hWnd)) {
					StringBuilder sb = new StringBuilder(2048);
					GetWindowText(hWnd, sb, 2048);
					int processId;
					GetWindowThreadProcessId(hWnd, out processId);
					windowList.Add(new Window {Title = sb.ToString(), Handle = (int)hWnd, ProcessId = processId});
				}
				return true;
			}
		}
	}
}