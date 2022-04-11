# FIXME: the returned list should be passed through in lParam, not as a global variable
Add-Type @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace ExplorerDirectory {
	public class Win32Window {
		public class Window {
			public string Title {get; set;}
			public int Handle {get; set;}
			public int ProcessId {get; set;}
		}

		private delegate bool CallBackPtr(IntPtr hwnd, IntPtr lParam);

		private static CallBackPtr callBackPtr = Callback;
		private static List<Window> _WinList = new List<Window>();

		[DllImport("User32.dll")]
		[return: MarshalAs(UnmanagedType.Bool)]
		private static extern bool EnumWindows(CallBackPtr lpEnumFunc, IntPtr lParam);

		[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
		private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

		[DllImport("User32.dll")]
		private static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);

		[DllImport("user32.dll")]
		[return: MarshalAs(UnmanagedType.Bool)]
		private static extern bool IsWindowVisible(IntPtr hWnd);

		private static bool Callback(IntPtr hWnd, IntPtr lparam) {
			if (IsWindowVisible(hWnd)) {
				StringBuilder sb = new StringBuilder(2048);
				GetWindowText(hWnd, sb, 2048);
				int processId;
				GetWindowThreadProcessId(hWnd, out processId);
				_WinList.Add(new Window {Title = sb.ToString(), Handle = (int)hWnd, ProcessId = processId});
			}
			return true;
		}   

		public static List<Window> GetWindows() {
			_WinList = new List<Window>();
			EnumWindows(callBackPtr, IntPtr.Zero);
			return _WinList;
		}
	}
}
"@

<#
	Returns all directories opened in File Explorer.
	File Explorer must have the option to list full path as window title enabled for this to work.
#>
function Get-ExplorerDirectory {
	[CmdletBinding()]
	[OutputType([IO.DirectoryInfo])]
	param()

	$ExplorerPids = Get-Process explorer -ErrorAction Ignore | % Id
	return [ExplorerDirectory.Win32Window]::GetWindows()
		| ? ProcessId -in $ExplorerPids
		| % Title
		# File Explorer windows have the full path as window title
		| ? {Test-Path -Type Container $_}
		| Get-Item
}

function Get-AltapSalamanderDirectory {
	[CmdletBinding()]
	[OutputType([IO.DirectoryInfo])]
	param()

	$SalamanderPids = Get-Process salamand -ErrorAction Ignore | % Id
	return [ExplorerDirectory.Win32Window]::GetWindows()
		| ? ProcessId -in $SalamanderPids
		| % Title
		# filter out windows like Find, Configuration,...
		| ? {$_ -like "*Altap Salamander*"}
		# Title is something like 'C:\Path - Altap Salamander 4.0 (x64)'
		| % {$i = $_.LastIndexOf(" - "); $_.Substring(0, $i)}
		| ? {Test-Path -Type Container $_}
		| Get-Item
}

function Get-FileManagerDirectory {
	[CmdletBinding()]
	[OutputType([IO.DirectoryInfo])]
	param()

	Get-ExplorerDirectory
	Get-AltapSalamanderDirectory
}
