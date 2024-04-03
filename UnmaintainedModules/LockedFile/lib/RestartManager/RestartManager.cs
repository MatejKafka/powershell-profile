using System;
using System.Runtime.InteropServices;

namespace LockedFile;

#nullable enable

public static class RestartManager {
    [DllImport(RestartManagerDll, CharSet = CharSet.Unicode)]
    public static extern int RmRegisterResources(
            uint pSessionHandle,
            uint nFiles,
            string[] rgsFilenames,
            uint nApplications,
            [In] RM_UNIQUE_PROCESS[]? rgApplications,
            uint nServices,
            string[]? rgsServiceNames
    );

    [DllImport(RestartManagerDll, CharSet = CharSet.Unicode)]
    public static extern int RmStartSession(
            out uint pSessionHandle,
            int dwSessionFlags,
            string strSessionKey
    );

    [DllImport(RestartManagerDll)]
    public static extern int RmEndSession(uint pSessionHandle);

    [DllImport(RestartManagerDll, CharSet = CharSet.Unicode)]
    public static extern int RmGetList(
            uint dwSessionHandle,
            out uint pnProcInfoNeeded,
            ref uint pnProcInfo,
            [In, Out] RM_PROCESS_INFO[]? rgAffectedApps,
            ref uint lpdwRebootReasons
    );

    /// <summary>
    /// Contains a 64-bit value representing the number of 100-nanosecond intervals since January 1, 1601 (UTC).
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    public struct FILETIME {
        /// <summary>
        /// The low-order part of the file time.
        /// </summary>
        public uint dwLowDateTime;

        /// <summary>
        /// The high-order part of the file time.
        /// </summary>
        public uint dwHighDateTime;
    }

    /// <summary>
    /// Uniquely identifies a process by its PID and the time the process began. An array of <see cref="RM_UNIQUE_PROCESS"/> structures can be passed to the <see cref="RmRegisterResources(uint, uint, string[], uint, RM_UNIQUE_PROCESS[], uint, string[])"/> function.
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    public struct RM_UNIQUE_PROCESS {
        /// <summary>
        /// The product identifier (PID).
        /// </summary>
        public uint dwProcessId;

        /// <summary>
        /// The creation time of the process. The time is provided as a <see cref="FILETIME"/> structure that is returned by the lpCreationTime parameter of the GetProcessTimes function.
        /// </summary>
        public FILETIME ProcessStartTime;
    }

    private static readonly int RM_SESSION_KEY_LEN = Guid.Empty.ToByteArray().Length; // 16-byte
    public static readonly int CCH_RM_SESSION_KEY = RM_SESSION_KEY_LEN * 2;

    private const string RestartManagerDll = "rstrtmgr.dll";

    public enum WinErrorCode {
        /// <summary>
        /// The function completed successfully.
        /// </summary>
        ERROR_SUCCESS = 0,

        /// <summary>
        /// Access is denied. This is also returned when a directory path is passed instead of a file path.
        /// </summary>
        ERROR_ACCESS_DENIED = 5,

        /// <summary>
        /// No Restart Manager session exists for the handle supplied.
        /// </summary>
        ERROR_INVALID_HANDLE = 6,

        /// <summary>
        /// A Restart Manager operation could not complete because not enough memory was available.
        /// </summary>
        ERROR_OUTOFMEMORY = 14,

        /// <summary>
        /// An operation was unable to read or write to the registry.
        /// </summary>
        ERROR_WRITE_FAULT = 29,

        /// <summary>
        /// The process cannot access the file because it is being used by another process.
        /// </summary>
        ERROR_SHARING_VIOLATION = 32,

        /// <summary>
        /// The process cannot access the file because another process has locked a portion of the file.
        /// </summary>
        ERROR_LOCK_VIOLATION = 33,

        /// <summary>
        /// A Restart Manager function could not obtain a Registry write mutex in the allotted time. A system restart is recommended because further use of the Restart Manager is likely to fail.
        /// </summary>
        ERROR_SEM_TIMEOUT = 121,

        /// <summary>
        /// One or more arguments are not correct. This error value is returned by the Restart Manager function if a <c>null</c> pointer or 0 is passed in a parameter that requires a non-<c>null</c> and non-zero value.
        /// </summary>
        ERROR_BAD_ARGUMENTS = 160,

        /// <summary>
        /// This error value is returned by the <see cref="RmGetList(uint, out uint, ref uint, RM_PROCESS_INFO[], ref uint)"/> function if the <i>rgAffectedApps</i> buffer is too small to hold all application information in the list.
        /// </summary>
        ERROR_MORE_DATA = 234,

        /// <summary>
        /// The maximum number of sessions has been reached.
        /// </summary>
        ERROR_MAX_SESSIONS_REACHED = 353,

        /// <summary>
        /// The current operation is canceled by user.
        /// </summary>
        ERROR_CANCELLED = 1223
    }

    /// <summary>
    /// Specifies the type of application that is described by the <see cref="RM_PROCESS_INFO"/> structure.
    /// </summary>
    public enum RM_APP_TYPE {
        /// <summary>
        /// The application cannot be classified as any other type. An application of this type can only be shut down by a forced shutdown.
        /// </summary>
        RmUnknownApp = 0,

        /// <summary>
        /// A Windows application run as a stand-alone process that displays a top-level window.
        /// </summary>
        RmMainWindow = 1,

        /// <summary>
        /// A Windows application that does not run as a stand-alone process and does not display a top-level window.
        /// </summary>
        RmOtherWindow = 2,

        /// <summary>
        /// The application is a Windows service.
        /// </summary>
        RmService = 3,

        /// <summary>
        /// The application is Windows Explorer.
        /// </summary>
        RmExplorer = 4,

        /// <summary>
        /// The application is a stand-alone console application.
        /// </summary>
        RmConsole = 5,

        /// <summary>
        /// A system restart is required to complete the installation because a process cannot be shut down. The process cannot be shut down because of the following reasons. The process may be a critical process. The current user may not have permission to shut down the process. The process may belong to the primary installer that started the Restart Manager.
        /// </summary>
        RmCritical = 1000
    }

    /// <summary>
    /// Describes the current status of an application that is acted upon by the Restart Manager.
    /// </summary>
    public enum RM_APP_STATUS : uint {
        /// <summary>
        /// The application is in a state that is not described by any other enumerated state.
        /// </summary>
        RmStatusUnknown = 0x0,

        /// <summary>
        /// The application is currently running.
        /// </summary>
        RmStatusRunning = 0x1,

        /// <summary>
        /// The Restart Manager has stopped the application.
        /// </summary>
        RmStatusStopped = 0x2,

        /// <summary>
        /// An action outside the Restart Manager has stopped the application.
        /// </summary>
        RmStatusStoppedOther = 0x4,

        /// <summary>
        /// The Restart Manager has restarted the application.
        /// </summary>
        RmStatusRestarted = 0x8,

        /// <summary>
        /// The Restart Manager encountered an error when stopping the application.
        /// </summary>
        RmStatusErrorOnStop = 0x10,

        /// <summary>
        /// The Restart Manager encountered an error when restarting the application.
        /// </summary>
        RmStatusErrorOnRestart = 0x20,

        /// <summary>
        /// Shutdown is masked by a filter.
        /// </summary>
        RmStatusShutdownMasked = 0x40,

        /// <summary>
        /// Restart is masked by a filter.
        /// </summary>
        RmStatusRestartMasked = 0x80
    }

    /// <summary>
    /// Describes the reasons a restart of the system is needed.
    /// </summary>
    public enum RM_REBOOT_REASON {
        /// <summary>
        /// A system restart is not required.
        /// </summary>
        RmRebootReasonNone = 0x0,

        /// <summary>
        /// The current user does not have sufficient privileges to shut down one or more processes.
        /// </summary>
        RmRebootReasonPermissionDenied = 0x1,

        /// <summary>
        /// One or more processes are running in another Terminal Services session.
        /// </summary>
        RmRebootReasonSessionMismatch = 0x2,

        /// <summary>
        /// A system restart is needed because one or more processes to be shut down are critical processes.
        /// </summary>
        RmRebootReasonCriticalProcess = 0x4,

        /// <summary>
        /// A system restart is needed because one or more services to be shut down are critical services.
        /// </summary>
        RmRebootReasonCriticalService = 0x8,

        /// <summary>
        /// A system restart is needed because the current process must be shut down.
        /// </summary>
        RmRebootReasonDetectedSelf = 0x10
    }

    /// <summary>
    /// Describes an application that is to be registered with the Restart Manager.
    /// </summary>
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct RM_PROCESS_INFO {
        /// <summary>
        /// Contains an <see cref="RM_UNIQUE_PROCESS"/> structure that uniquely identifies the application by its PID and the time the process began.
        /// </summary>
        public RM_UNIQUE_PROCESS Process;

        /// <summary>
        /// If the process is a service, this parameter returns the long name for the service. If the process is not a service, this parameter returns the user-friendly name for the application. If the process is a critical process, and the installer is run with elevated privileges, this parameter returns the name of the executable file of the critical process. If the process is a critical process, and the installer is run as a service, this parameter returns the long name of the critical process.
        /// </summary>
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCH_RM_MAX_APP_NAME + 1)]
        public string strAppName;

        /// <summary>
        /// If the process is a service, this is the short name for the service. This member is not used if the process is not a service.
        /// </summary>
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCH_RM_MAX_SVC_NAME + 1)]
        public string strServiceShortName;

        /// <summary>
        /// Contains an <see cref="RM_APP_TYPE"/> enumeration value that specifies the type of application as <see cref="RM_APP_TYPE.RmUnknownApp"/>, <see cref="RM_APP_TYPE.RmMainWindow"/>, <see cref="RM_APP_TYPE.RmOtherWindow"/>, <see cref="RM_APP_TYPE.RmService"/>, <see cref="RM_APP_TYPE.RmExplorer"/> or <see cref="RM_APP_TYPE.RmCritical"/>.
        /// </summary>
        public RM_APP_TYPE ApplicationType;

        /// <summary>
        /// Contains a bit mask that describes the current status of the application. See the <see cref="RM_APP_STATUS"/> enumeration.
        /// </summary>
        public RM_APP_STATUS AppStatus;

        /// <summary>
        /// Contains the Terminal Services session ID of the process. If the terminal session of the process cannot be determined, the value of this member is set to RM_INVALID_SESSION (-1). This member is not used if the process is a service or a system critical process.
        /// </summary>
        public uint TSSessionId;

        /// <summary>
        /// <c>true</c> if the application can be restarted by the Restart Manager; otherwise, <c>false</c>. This member is always <c>true</c> if the process is a service. This member is always <c>false</c> if the process is a critical system process.
        /// </summary>
        [MarshalAs(UnmanagedType.Bool)]
        public bool bRestartable;

        private const int CCH_RM_MAX_APP_NAME = 255;
        private const int CCH_RM_MAX_SVC_NAME = 63;
    }
}