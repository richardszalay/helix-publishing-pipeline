using System;
using System.IO;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public interface IFileSystem
    {
        bool Exists(string targetFilePath);
        Stream OpenRead(string sourceFile);
    }

    public class FileSystem : IFileSystem
    {
        public bool Exists(string path)
        {
            return File.Exists(path);
        }

        public Stream OpenRead(string path)
        {
            return File.OpenRead(path);
        }
    }
}
