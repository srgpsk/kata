<?php
declare(strict_types=1);

namespace My;

const MAX_RECORDS = 10_000_000;
const USE_CHUNKS = true;
const MAX_RECORDS_PER_CHUNK = MAX_RECORDS / 10;
const OUT_PATH = '/tmp';

//withTracking()(generateDataFiles(...));
withTracking()(function () {
//    for ($i = 0; $i < 1_000_000; $i++) str_replace(['/', '+', '='], '', base64_encode(random_bytes(30)));
//    for ($i = 0; $i < 1_000_000; $i++) str_replace([0,1,2,3,4,5,6,7,8,9], '', hash('xxh3', "$i"));
//    $getRandomString = getGenerator();
//    for ($i = 0; $i < 1_000_000; $i++) {
//        if (empty($getRandomString->current())) $getRandomString = getGenerator();
//
//        $cur = $getRandomString->current();
////        log("cur $cur");
//        $getRandomString->next();
//    }
//    for ($i = 0; $i < 1_000_000; $i++)
    generateDataFiles();
});

function generateDataFiles(): void
{
    $data = '';
    $ioBufferSize = 1000;

    $hr = toHumanReadable(MAX_RECORDS);
    log("Starting process of $hr records generation.");

    $dest = getDestination(strtolower($hr));
//    $handle = fopen($dest, 'w');
    log("Output file: $dest");

    $getRandomString = getGenerator();
    for ($i = 0; $i <= MAX_RECORDS; $i++) {
        if (empty($getRandomString->current())) $getRandomString = getGenerator();
        $p1 = $getRandomString->current();
        $getRandomString->next();
        $p2 = $getRandomString->current();
        $getRandomString->next();
        $email = "$p1@$p2.com";
        $name = $p2;
        $data .= "$email, $name" . PHP_EOL;
        $rowNumber = $i+1;

        // create chunked output
        if (USE_CHUNKS &&  % MAX_RECORDS_PER_CHUNK === 0) {
            if (isset($handle)) fclose($handle);

            $fileSuffix = (string)intdiv($i, MAX_RECORDS_PER_CHUNK);
            $dest = getDestination($fileSuffix);
            $handle = fopen($dest, 'w');

            log("Writing in output file $dest");
        }

        // reduce I/O
        if ($i > 0 && $i % $ioBufferSize === 0) {
//            fwrite($handle, $data);
//            sleep(1);
            $data = '';
            logProgress($i);

        }

    }
//    fwrite($handle, $data);
//    fclose($handle);
    log('Finished.');
}

function getGenerator(): \Generator
{
    $seed = strtolower(
        str_replace(['/', '+', '='], '',
            base64_encode(random_bytes(100))
        )
    );
    $len = rand(6, 12);
    $seedEnd = strlen($seed) - $len;
//            log('seed ' . $seed);

    $i = 0;
    do {
        yield substr($seed, $i, $len);
        $i++;
    } while ($i < $seedEnd);
}

/**
 * Never underestimate a bruteforce
 */
function getRandomStringBf(): string
{
    $seed = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',];
    $seedLen = 35;
    $len = rand(6, 12);
    $res = '';

    for ($i = 0; $i < $len; $i++) {
//        $c = chr(rand(97, 122));
        $res .= $seed[rand(0, $seedLen)];
    }

    return $res;
}

function generateWithAbstraction()
{
    $generator = new class implements \Iterator {
        private \Generator $generator;

        public function __construct()
        {
            $this->generator = $this->createGenerator();
        }

        private function createGenerator(): \Generator
        {
            $seed = strtolower(
                str_replace(['/', '+', '='], '',
                    base64_encode(random_bytes(100))
                )
            );
            $len = rand(6, 12);
            $seedEnd = strlen($seed) - $len;
//            log('seed ' . $seed);

            $i = 0;
            do {
                yield substr($seed, $i, $len);
                $i++;
            } while ($i < $seedEnd);
        }

        public function rewind(): void
        {
            $this->generator = $this->createGenerator();
        }

        public function current(): mixed
        {
            return $this->generator->current();
        }

        public function next(): void
        {
            $this->generator->next();
        }

        public function key(): mixed
        {
            return $this->generator->key();
        }

        public function valid(): bool
        {
            return $this->generator->valid();

        }
    };
    $iterator = new \CachingIterator($generator, \CachingIterator::TOSTRING_USE_CURRENT);
    $iterator->next(); // first value is null

    return function () use ($iterator) {
        $val = $iterator->current();
//        log('val ' . $val);

        if (!$iterator->hasNext()) $iterator->rewind();
        $iterator->next();

        return $val;
    };
}


//function getGenerator

function logProgress(int $iteration): void
{
    $max = USE_CHUNKS ? MAX_RECORDS_PER_CHUNK : MAX_RECORDS;
//    $chunkNumber = USE_CHUNKS ? intdiv($iteration, MAX_RECORDS_PER_CHUNK) : $iteration;
//    $recordsInChunk = intdiv($iteration , $chunkNumber);
    $recordsInChunk = $iteration;
    $percentage = intdiv($iteration * 100 , $max);
    echo "\rProgress: $percentage%";

//    if ($iteration % MAX_RECORDS_PER_CHUNK === 0) echo PHP_EOL . 'Records written to current file: ' . toHumanReadable($recordsInChunk) .  PHP_EOL;
}

function getDestination(string $suffix): string
{
    return sprintf('%s/user%s.txt', OUT_PATH, $suffix);
}

function log(string $msg): void
{
    echo $msg . PHP_EOL;
}

function toHumanReadable(float|int $num): string
{
    $divider = 1000;
    static $divCount = 0;

    if ($num < $divider) {
        $suffix = match ($divCount) {
            1 => 'K', // thousands
            2 => 'M', // mil
            3 => 'B', // bil
            default => 'Come on bro, it\'s PHP.'
        };
        $divCount = 0;
        return $num . $suffix;
    }

    $num = intdiv($num, $divider);
    ++$divCount;

    return toHumanReadable($num);
}

function withTracking(): callable
{
    return function (callable $f, ...$args): array {
        $start = microtime(true);
        $startMemory = memory_get_peak_usage();

        $f(...$args);

        $end = microtime(true);
        $endMemory = memory_get_peak_usage();

        $executionTime = $end - $start;
        $memoryUsage = $endMemory - $startMemory;

        echo "Script execution time: " . round($executionTime, 2) . " seconds" . PHP_EOL;
        echo "Peak memory usage: " . $memoryUsage . " bytes";
    };
}
