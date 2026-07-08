/system script
add name=generate-isolir-url source="
# --- Konfigurasi Web Proxy Isolir ---
# IP:Port ini TETAP dan tidak pernah diubah oleh script.
# Yang berubah per pelanggan hanyalah query string di belakangnya (?username=...dst),
# bukan IP/port tujuannya.
:local baseUrl \"http://10.10.10.1:8080\"

# --- Fungsi URL-Encode sederhana ---
# Mengamankan karakter yang bisa merusak URL (spasi, &, #, +, %)
# jika muncul di nama paket / username.
:local urlEncode do={
    :local result \"\"
    :local input \$1
    :local len [:len \$input]
    :local i 0
    :while (\$i < \$len) do={
        :local ch [:pick \$input \$i (\$i+1)]
        :if (\$ch = \" \") do={ :set result (\$result . \"%20\") } else={
        :if (\$ch = \"&\") do={ :set result (\$result . \"%26\") } else={
        :if (\$ch = \"#\") do={ :set result (\$result . \"%23\") } else={
        :if (\$ch = \"+\") do={ :set result (\$result . \"%2B\") } else={
        :if (\$ch = \"%\") do={ :set result (\$result . \"%25\") } else={
            :set result (\$result . \$ch)
        }}}}}
        :set i (\$i + 1)
    }
    :return \$result
}

# --- Fungsi Parsing Comment ---
# Berfungsi membaca format: paket=...;tagihan=...;periode=...;tempo=...
:local parseComment do={
    :local start [:find \$1 (\$2 . \"=\")]
    :if ([:typeof \$start] != \"nil\") do={
        :local valStart (\$start + [:len \$2] + 1)
        :local valEnd [:find \$1 \";\" \$valStart]
        :if ([:typeof \$valEnd] = \"nil\") do={ :set valEnd [:len \$1] }
        :return [:pick \$1 \$valStart \$valEnd]
    }
    :return \"\"
}

# --- Loop User Aktif ---
:foreach i in=[/ppp active find] do={
    :local user [/ppp active get \$i name]
    :local ipUser [/ppp active get \$i address]

    :if ([:len [/ppp secret find name=\$user]] > 0) do={
        :local profileName [/ppp secret get [find name=\$user] profile]

        # Hanya memproses user yang sedang terisolir (Profile mengandung kata ISOLIR)
        :if ([:typeof [:find \$profileName \"ISOLIR\"]] != \"nil\") do={
            :local commentData [/ppp secret get [find name=\$user] comment]

            # Mengekstrak data metadata teknis dari comment
            :local pPaket [\$parseComment \$commentData \"paket\"]
            :local pTagihan [\$parseComment \$commentData \"tagihan\"]
            :local pPeriode [\$parseComment \$commentData \"periode\"]
            :local pTempo [\$parseComment \$commentData \"tempo\"]

            # Jika 'paket' di comment kosong, gunakan nama profile sebagai fallback
            :if (\$pPaket = \"\") do={ :set pPaket \$profileName }
            # Jika 'tagihan' kosong, default ke 0 supaya error.html tidak menampilkan \"Rp NaN\"
            :if (\$pTagihan = \"\") do={ :set pTagihan \"0\" }

            # Encode nilai yang berpotensi mengandung spasi/simbol
            :local eUser [\$urlEncode \$user]
            :local ePaket [\$urlEncode \$pPaket]
            :local eTagihan [\$urlEncode \$pTagihan]
            :local ePeriode [\$urlEncode \$pPeriode]
            :local eTempo [\$urlEncode \$pTempo]

            # Menyusun parameter URL sesuai kebutuhan index.html DESANET
            # PENTING: tanda tanya HARUS \"?\" polos, bukan \"\\?\" (backslash akan
            # ikut masuk ke URL dan membuat redirect-nya rusak/berubah).
            :local isolirUrl (\$baseUrl . \"?username=\" . \$eUser . \"&paket=\" . \$ePaket . \"&tagihan=\" . \$eTagihan . \"&periode=\" . \$ePeriode . \"&tempo=\" . \$eTempo)

            :log warning (\"[DESANET ISOLIR] Redirect URL Generated for \" . \$user)

            # --- OTOMATISASI PROXY ACCESS ---
            # 1. Hapus rule redirect lama untuk IP ini HANYA yang dibuat oleh script ini
            #    (difilter lewat comment, supaya rule access lain yang dibuat manual
            #    dengan src-address sama tidak ikut terhapus).
            /ip proxy access remove [find src-address=\$ipUser comment~\"Auto-Isolir\"]

            # 2. Tambahkan rule deny baru untuk me-redirect user ke URL spesifik mereka.
            #    baseUrl (IP:port web proxy) tidak pernah berubah; hanya query string
            #    di belakangnya yang unik per pelanggan.
            /ip proxy access add action=deny src-address=\$ipUser redirect-to=\$isolirUrl comment=(\"Auto-Isolir: \" . \$user)
        }
    } else={
        :log error (\"[DESANET ISOLIR] User \$user aktif tapi tidak ditemukan di PPP Secret!\")
    }
}
"
