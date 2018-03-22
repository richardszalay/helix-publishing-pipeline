using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.IO;
using System.Linq;

namespace RichardSzalay.Helix.Publishing.Tasks
{
    public class FilterBinaryUnchangedFiles : Task
    {
        private readonly IFileSystem fileSystem;

        [Required]
        public ITaskItem[] Files { get; set; }

        [Required]
        public string RelativePathMetadata { get; set; }

        [Required]
        public string TargetDirectory { get; set; }

        [Output]
        public ITaskItem[] Output { get; set; }

        public FilterBinaryUnchangedFiles()
            : this(new FileSystem())
        {
        }

        public FilterBinaryUnchangedFiles(IFileSystem fileSystem)
        {
            this.fileSystem = fileSystem;
        }

        public override bool Execute()
        {
            if (Files == null || Files.Length == 0)
            {
                Log.LogError("No files were supplied");
                return false;
            }

            try
            {
                Output = Files
                    .Where(file => !InBinaryChangedFile(file))
                    .ToArray();

                return true;
            }
            catch (Exception ex)
            {
                Log.LogErrorFromException(ex);
                return false;
            }
        }

        private bool InBinaryChangedFile(ITaskItem file)
        {
            var relativePath = file.GetMetadata(RelativePathMetadata);
            var sourceFile = file.GetMetadata("FullPath");

            if (relativePath == string.Empty)
            {
                return true;
            }

            var targetFilePath = Path.Combine(this.TargetDirectory, relativePath);

            if (!fileSystem.Exists(targetFilePath))
            {
                return true;
            }

            using (var sourceStream = fileSystem.OpenRead(sourceFile))
            using (var targetStream = fileSystem.OpenRead(targetFilePath))
            {
                return !AreStreamsEqual(sourceStream, targetStream);
            }

        }

        const int BufferSize = 4096;

        private bool AreStreamsEqual(Stream streamA, Stream streamB)
        {
            byte[] bufferA = new byte[BufferSize];
            byte[] bufferB = new byte[BufferSize];

            int bytesReadA = streamA.Read(bufferA, 0, BufferSize);
            int bytesReadB = streamB.Read(bufferB, 0, BufferSize);

            while (bytesReadA == bytesReadB)
            {
                if (bytesReadA == 0)
                {
                    return true;
                }

                for (int i=0; i<bytesReadA; i++)
                {
                    if (bufferA[i] != bufferB[i])
                    {
                        return false;
                    }
                }

                bytesReadA = streamA.Read(bufferA, 0, BufferSize);
                bytesReadB = streamB.Read(bufferB, 0, BufferSize);
            }

            return false;
        }
    }
}
