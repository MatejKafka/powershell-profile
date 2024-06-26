using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace LockedFile;

#nullable enable

public static class FileUtils {
    public static string[] GetLockedFiles(string directory) {
        return Directory.EnumerateFiles(directory, "*", SearchOption.AllDirectories)
                .AsParallel()
                .Where(f => {
                    try {
                        // this is not much slower than calling raw `CreateFile` (~4% in my testing)
                        File.OpenWrite(f).Close();
                        return false;
                    } catch (SystemException e) {
                        switch (e.HResult) {
                            case -2147024864: // 0x80070020 = ERROR_SHARING_VIOLATION
                                return true;
                            case -2147024891: // 0x80070005 = ERROR_ACCESS_DENIED
                                return false; // ignore
                            case -2147022976: // 0x80070780 = ERROR_CANT_ACCESS_FILE
                                return false; // sometimes happens for special files, ignore
                            default:
                                throw;
                        }
                    }
                })
                .ToArray();
    }
}