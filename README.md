
[![Live Demo](https://img.shields.io/badge/Live-Demo-brightgreen?style=for-the-badge)](https://rovanid.github.io/desanet/)

---

# TUTORIAL SISTEM ISOLIR PPPoE MIKROTIK

## Versi Dokumentasi

Sistem ini digunakan untuk melakukan isolir pelanggan PPPoE secara manual maupun otomatis.

Fungsi utama:

- Memindahkan pelanggan ke profile ISOLIR.
- Memberikan bandwidth terbatas.
- Memblokir akses internet.
- Mengarahkan pelanggan ke halaman informasi pembayaran.
- Menyimpan informasi tagihan pada comment PPP Secret.


==================================================

# 1. FORMAT COMMENT USER PPP SECRET

Setiap user PPPoE wajib memiliki data tagihan pada comment.

Format:

paket=PAKET-20M;tagihan=150000;periode=Juli-2026;tempo=05-07-2026


Contoh:

paket=PAKET-20M;tagihan=150000;periode=Juli-2026;tempo=05-07-2026


Keterangan:

paket
=
Nama profile atau paket internet pelanggan.


tagihan
=
Nominal pembayaran pelanggan.


periode
=
Bulan tagihan pelanggan.


tempo
=
Tanggal jatuh tempo pembayaran.



Contoh lain:

paket=PAKET-50M;tagihan=250000;periode=Agustus-2026;tempo=05-08-2026



==================================================

# 2. PEMBUATAN PROFILE ISOLIR


## 2.1 Membuat IP Pool ISOLIR


Buat pool IP khusus pelanggan yang terkena isolir.


Command:

/ip pool add name="POOL-ISOLIR" ranges=[ISI IP AWAL-ISI IP AKHIR]


Contoh:

/ip pool add name="POOL-ISOLIR" ranges=10.10.10.2-10.10.10.254



Keterangan:

POOL-ISOLIR
=
Nama pool khusus user isolir.


ranges
=
Range IP yang akan diberikan kepada pelanggan isolir.



Contoh topologi:

Gateway:

10.10.10.1


Pool:

10.10.10.2-10.10.10.254



==================================================

# 2.2 Membuat PPP Profile ISOLIR


Profile ini digunakan saat pelanggan tidak melakukan pembayaran.


Command:


/ppp profile add \
name="ISOLIR" \
local-address=[ISI IP GATEWAY] \
remote-address=POOL-ISOLIR \
address-list="ISOLIR-LIST" \
rate-limit="1M/1M"



Contoh:


/ppp profile add \
name="ISOLIR" \
local-address=10.10.10.1 \
remote-address=POOL-ISOLIR \
address-list="ISOLIR-LIST" \
rate-limit="1M/1M"



Penjelasan:

name
=
Nama profile PPP.


local-address
=
IP gateway PPP.


remote-address
=
Mengambil IP dari POOL-ISOLIR.


address-list
=
Memasukkan IP user ke firewall address-list.


rate-limit
=
Pembatasan bandwidth pelanggan.



==================================================

# 2.3 Alternatif Bandwidth ISOLIR


Jika ingin memberikan bandwidth berbeda:


Contoh:


/ppp profile add \
name="ISOLIR-512K" \
local-address=[ISI IP GATEWAY] \
remote-address=POOL-ISOLIR \
address-list="ISOLIR-LIST" \
rate-limit="512k/512k"



Atau:

/ppp profile add \
name="ISOLIR-2M" \
local-address=[ISI IP GATEWAY] \
remote-address=POOL-ISOLIR \
address-list="ISOLIR-LIST" \
rate-limit="2M/2M"



Catatan:

Tidak boleh membuat dua profile dengan nama yang sama.

Contoh salah:

name="ISOLIR"
name="ISOLIR"


Gunakan nama berbeda jika memiliki beberapa level isolir.



==================================================

LANJUT PART 2/3:
- Firewall filter blokir internet
- NAT redirect web isolir
- Web proxy
- Pindah profile user PPP Secret
- Pembukaan isolir

==================================================

# 3. FIREWALL FILTER ISOLIR


Firewall digunakan untuk membatasi akses pelanggan yang masuk ke address-list ISOLIR-LIST.


Tujuan:

- Memblokir semua akses internet.
- Tetap mengizinkan akses web isolir.
- Tetap mengizinkan DNS.


==================================================

# 3.1 Blokir Internet TCP


Command:


/ip firewall filter
add action=drop \
chain=forward \
comment="Blokir Internet Isolir (Selain Port Web)" \
dst-port=!80,8080,53 \
protocol=tcp \
src-address-list="ISOLIR-LIST"



Penjelasan:


chain=forward

Memfilter trafik yang melewati router.


action=drop

Menolak koneksi.


protocol=tcp

Filter koneksi TCP.


dst-port=!80,8080,53

Semua port TCP diblokir kecuali:

80
=
HTTP Web


8080
=
Web Proxy Isolir


53
=
DNS



src-address-list="ISOLIR-LIST"

Hanya berlaku untuk pelanggan isolir.



==================================================

# 3.2 Blokir UDP Selain DNS


Command:


/ip firewall filter
add action=drop \
chain=forward \
dst-port=!53 \
protocol=udp \
src-address-list="ISOLIR-LIST"



Penjelasan:


UDP selain port 53 akan diblokir.


Port 53 tetap dibuka untuk kebutuhan DNS.



==================================================

# 4. REDIRECT TRAFFIC KE HALAMAN ISOLIR


Agar pelanggan yang membuka website diarahkan ke halaman informasi pembayaran.


Pastikan Web Proxy MikroTik sudah aktif.


Aktifkan Web Proxy:


/ip proxy set enabled=yes port=8080



==================================================


# 4.1 NAT REDIRECT ISOLIR


Command:


/ip firewall nat
add action=redirect \
chain=dstnat \
comment="Redirect Isolir ke Web Proxy" \
dst-port=80 \
protocol=tcp \
src-address-list="ISOLIR-LIST" \
to-ports=8080



Penjelasan:


action=redirect

Mengalihkan trafik ke router.


dst-port=80

Target koneksi HTTP.


to-ports=8080

Diarahkan ke Web Proxy.



==================================================

# 5. MEMBUAT HALAMAN INFORMASI ISOLIR


Halaman isolir dapat berisi:


- Nama pelanggan.
- Status internet.
- Jumlah tagihan.
- Periode tagihan.
- Tanggal jatuh tempo.
- Nomor pembayaran.
- Kontak admin.



Contoh tampilan:


================================

INTERNET TERISOLIR


Pelanggan:
JOHN


Paket:
PAKET-20M


Tagihan:
Rp150.000


Periode:
Juli-2026


Jatuh Tempo:
05-07-2026


Silahkan lakukan pembayaran
untuk mengaktifkan kembali layanan.


================================



==================================================

# 6. PINDAH USER KE PROFILE ISOLIR


Ketika pelanggan belum membayar, ubah profile PPP Secret.


Format:


/ppp secret set [find name="NAMA SECRET"] profile="ISOLIR"



Contoh:


/ppp secret set [find name="budi"] profile="ISOLIR"



Setelah berhasil:


Sebelum:


Name:
budi


Profile:
PAKET-20M



Sesudah:


Name:
budi


Profile:
ISOLIR



==================================================

# 7. UPDATE COMMENT USER SAAT PINDAH PROFILE


Sebelum isolir:


PPP Secret:


Name:
budi


Profile:
PAKET-20M


Comment:


paket=PAKET-20M;tagihan=150000;periode=Juli-2026;tempo=05-07-2026



==================================================


Saat pelanggan masuk isolir:


Profile berubah:


PAKET-20M

menjadi:

ISOLIR



Comment tetap:


paket=PAKET-20M;tagihan=150000;periode=Juli-2026;tempo=05-07-2026



Data comment digunakan untuk menampilkan informasi pada halaman isolir.



==================================================

LANJUT PART 3/3:
- Pembukaan isolir setelah pembayaran
- Script otomatis isolir
- Integrasi Billing App
- Sinkronisasi PPP Secret MikroTik
- Checklist troubleshooting

==================================================

# 8. PEMBUKAAN ISOLIR SETELAH PEMBAYARAN


Jika pelanggan sudah melakukan pembayaran, kembalikan profile PPP Secret ke paket normal.


Format:


/ppp secret set [find name="NAMA SECRET"] profile="NAMA PROFILE"



Contoh:


/ppp secret set [find name="budi"] profile="PAKET-20M"



Hasil:


Sebelum:


Name:
budi


Profile:
ISOLIR



Sesudah:


Name:
budi


Profile:
PAKET-20M



==================================================

# 9. RECONNECT USER PPPoE


Setelah perubahan profile, pelanggan perlu reconnect agar mendapatkan konfigurasi baru.


Cara manual:


/ppp active remove [find name="NAMA USER"]



Contoh:


/ppp active remove [find name="budi"]



Setelah reconnect:


- User mendapatkan IP paket normal.
- Keluar dari address-list ISOLIR-LIST.
- Internet kembali normal.



==================================================

# 10. CEK USER ISOLIR


Melihat user aktif:


/ppp active print



Melihat profile secret:


/ppp secret print



Melihat address-list isolir:


/ip firewall address-list print where list="ISOLIR-LIST"



==================================================

# 11. SISTEM OTOMATIS ISOLIR


Konsep otomatis:


Billing App
        |
        |
        V

Cek tanggal jatuh tempo

        |
        |
        V

Jika belum bayar

        |
        |
        V

Update PPP Secret

        |
        |
        V

Profile = ISOLIR



==================================================

# 12. CONTOH SCRIPT MIKROTIK ISOLIR MANUAL


Contoh mencari user berdasarkan comment:


/ppp secret print where comment~"tempo"



Contoh ubah profile:


/ppp secret set [find name="budi"] profile="ISOLIR"



==================================================

# 13. INTEGRASI DENGAN BILLING APP


Data yang dikirim ke MikroTik:


Username PPPoE:

budi


Profile:


PAKET-20M


Comment:


paket=PAKET-20M;tagihan=150000;periode=Juli-2026;tempo=05-07-2026



Ketika jatuh tempo:


API MikroTik menjalankan:


/ppp secret set [find name="budi"] profile="ISOLIR"



Ketika pembayaran berhasil:


API MikroTik menjalankan:


/ppp secret set [find name="budi"] profile="PAKET-20M"



==================================================

# 14. TROUBLESHOOTING


## User tidak masuk isolir


Cek profile:


/ppp secret print



Pastikan:


Profile = ISOLIR



==================================================


## User sudah ISOLIR tapi internet masih jalan


Cek address-list:


/ip firewall address-list print



Pastikan IP user muncul:


ISOLIR-LIST



Jika tidak muncul:

- User belum reconnect.
- Profile belum menggunakan address-list.
- Salah nama address-list.



==================================================


## Redirect halaman tidak muncul


Cek Web Proxy:


/ip proxy print



Pastikan:


enabled=yes

port=8080



Cek NAT:


/ip firewall nat print



Pastikan rule redirect aktif.



==================================================

# 15. URUTAN KONFIGURASI REKOMENDASI


1. Buat IP Pool Isolir


2. Buat PPP Profile ISOLIR


3. Aktifkan Address List ISOLIR-LIST


4. Aktifkan Web Proxy


5. Buat Firewall Filter


6. Buat NAT Redirect


7. Ubah PPP Secret ke ISOLIR


8. Test koneksi pelanggan



==================================================

# 16. CONTOH FLOW PELANGGAN


NORMAL:


PPP Secret

↓

Profile:
PAKET-20M

↓

Internet Normal



==================================================


BELUM BAYAR:


PPP Secret

↓

Profile:
ISOLIR

↓

IP Pool ISOLIR

↓

Address List:
ISOLIR-LIST

↓

Firewall Block

↓

Redirect Web Proxy

↓

Halaman Pembayaran



==================================================


SUDAH BAYAR:


PPP Secret

↓

Profile:
PAKET-20M

↓

Reconnect PPPoE

↓

Internet Aktif Kembali



==================================================

# SELESAI


Dokumentasi Sistem Isolir PPPoE MikroTik

Fitur:

✓ Manual Isolir  
✓ Manual Buka Isolir  
✓ Limit Bandwidth  
✓ Redirect Halaman Pembayaran  
✓ Support Billing System  
✓ Support PPPoE Secret  
✓ Support Integrasi MikroTik API
