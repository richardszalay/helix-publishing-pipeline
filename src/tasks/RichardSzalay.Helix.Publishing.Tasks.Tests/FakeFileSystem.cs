using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace RichardSzalay.Helix.Publishing.Tasks.Tests
{
    public class FakeFileSystem : IFileSystem
    {
        readonly Dictionary<string, byte[]> files = new Dictionary<string, byte[]>();

        public bool Exists(string path)
        {
            return files.ContainsKey(path);
        }

        public Stream OpenRead(string path)
        {
            return new MemoryStream(files[path]);
        }

        public void AddFile(string path, string contents)
        {
            files[path] = Encoding.UTF8.GetBytes(contents);
        }
    }
}
