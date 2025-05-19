import keccak_pkg::STATE_WIDTH;
import keccak_pkg::w;

module keccak_round (
  input  logic [STATE_WIDTH-1:0] rin,
  input  logic [w-1:0]           rc,
  output logic [STATE_WIDTH-1:0] rout
);

  //-----------------------------------------------------------------------------  
  // rotate-left function
  function automatic logic [w-1:0] rolx(input logic [w-1:0] x, input int r);
    rolx = (x << r) | (x >> (w-r));
  endfunction

  //-----------------------------------------------------------------------------  
  // lane signals
  logic [w-1:0] Aba, Abe, Abi, Abo, Abu;
  logic [w-1:0] Aga, Age, Agi, Ago, Agu;
  logic [w-1:0] Aka, Ake, Aki, Ako, Aku;
  logic [w-1:0] Ama, Ame, Ami, Amo, Amu;
  logic [w-1:0] Asa, Ase, Asi, Aso, Asu;

  // intermediate θ, ρ/π, χ signals
  logic [w-1:0] Ca, Ce, Ci, Co, Cu;
  logic [w-1:0] Da, De, Di, Do, Du;
  logic [w-1:0] Aba_wire, Age_wire, Aki_wire, Amo_wire, Asu_wire;
  logic [w-1:0] Abo_wire, Agu_wire, Aka_wire, Ame_wire, Asi_wire;
  logic [w-1:0] Abe_wire, Agi_wire, Ako_wire, Amu_wire, Asa_wire;
  logic [w-1:0] Abu_wire, Aga_wire, Ake_wire, Ami_wire, Aso_wire;
  logic [w-1:0] Ase_wire, Abi_wire, Ago_wire, Aku_wire, Ama_wire;

  logic [w-1:0] Bba, Bbe, Bbi, Bbo, Bbu;
  logic [w-1:0] Bga, Bge, Bgi, Bgo, Bgu;
  logic [w-1:0] Bka, Bke, Bki, Bko, Bku;
  logic [w-1:0] Bma, Bme, Bmi, Bmo, Bmu;
  logic [w-1:0] Bsa, Bse, Bsi, Bso, Bsu;

  logic [w-1:0] Eba, Ebe, Ebi, Ebo, Ebu, Eba_wire;
  logic [w-1:0] Ega, Ege, Egi, Ego, Egu;
  logic [w-1:0] Eka, Eke, Eki, Eko, Eku;
  logic [w-1:0] Ema, Eme, Emi, Emo, Emu;
  logic [w-1:0] Esa, Ese, Esi, Eso, Esu;

  //-----------------------------------------------------------------------------  
  // extract the 25 lanes from the 1600-bit input
  assign Aba = rin[1599:1536];
  assign Abe = rin[1535:1472];
  assign Abi = rin[1471:1408];
  assign Abo = rin[1407:1344];
  assign Abu = rin[1343:1280];
  assign Aga = rin[1279:1216];
  assign Age = rin[1215:1152];
  assign Agi = rin[1151:1088];
  assign Ago = rin[1087:1024];
  assign Agu = rin[1023:960];
  assign Aka = rin[ 959: 896];
  assign Ake = rin[ 895: 832];
  assign Aki = rin[ 831: 768];
  assign Ako = rin[ 767: 704];
  assign Aku = rin[ 703: 640];
  assign Ama = rin[ 639: 576];
  assign Ame = rin[ 575: 512];
  assign Ami = rin[ 511: 448];
  assign Amo = rin[ 447: 384];
  assign Amu = rin[ 383: 320];
  assign Asa = rin[ 319: 256];
  assign Ase = rin[ 255: 192];
  assign Asi = rin[ 191: 128];
  assign Aso = rin[ 127:  64];
  assign Asu = rin[  63:   0];

  //-----------------------------------------------------------------------------  
  // θ step
  assign Ca = Aba ^ Aga ^ Aka ^ Ama ^ Asa;
  assign Ce = Abe ^ Age ^ Ake ^ Ame ^ Ase;
  assign Ci = Abi ^ Agi ^ Aki ^ Ami ^ Asi;
  assign Co = Abo ^ Ago ^ Ako ^ Amo ^ Aso;
  assign Cu = Abu ^ Agu ^ Aku ^ Amu ^ Asu;

  assign Da = Cu ^ rolx(Ce, 1);
  assign De = Ca ^ rolx(Ci, 1);
  assign Di = Ce ^ rolx(Co, 1);
  assign Do = Ci ^ rolx(Cu, 1);
  assign Du = Co ^ rolx(Ca, 1);

  //-----------------------------------------------------------------------------  
  // combined ρ, π, χ, ι sequence
  assign Aba_wire = Aba ^ Da;        assign Bba = Aba_wire;
  assign Age_wire = Age ^ De;        assign Bbe = rolx(Age_wire, 44);
  assign Aki_wire = Aki ^ Di;        assign Bbi = rolx(Aki_wire, 43);
  assign Eba_wire = Bba ^ ((~Bbe) & Bbi);
  assign Eba       = Eba_wire ^ rc;

  assign Amo_wire = Amo ^ Do;        assign Bbo = rolx(Amo_wire, 21);
  assign Ebe       = Bbe ^ ((~Bbi) & Bbo);

  assign Asu_wire = Asu ^ Du;        assign Bbu = rolx(Asu_wire, 14);
  assign Ebi       = Bbi ^ ((~Bbo) & Bbu);

  assign Ebo       = Bbo ^ ((~Bbu) & Bba);
  assign Ebu       = Bbu ^ ((~Bba) & Bbe);

  assign Abo_wire = Abo ^ Do;        assign Bga = rolx(Abo_wire, 28);
  assign Agu_wire = Agu ^ Du;        assign Bge = rolx(Agu_wire, 20);
  assign Aka_wire = Aka ^ Da;        assign Bgi = rolx(Aka_wire,  3);
  assign Ega       = Bga ^ ((~Bge) & Bgi);

  assign Ame_wire = Ame ^ De;        assign Bgo = rolx(Ame_wire, 45);
  assign Ege       = Bge ^ ((~Bgi) & Bgo);

  assign Asi_wire = Asi ^ Di;        assign Bgu = rolx(Asi_wire, 61);
  assign Egi       = Bgi ^ ((~Bgo) & Bgu);

  assign Ego       = Bgo ^ ((~Bgu) & Bga);
  assign Egu       = Bgu ^ ((~Bga) & Bge);

  assign Abe_wire = Abe ^ De;        assign Bka = rolx(Abe_wire,  1);
  assign Agi_wire = Agi ^ Di;        assign Bke = rolx(Agi_wire,  6);
  assign Ako_wire = Ako ^ Do;        assign Bki = rolx(Ako_wire, 25);
  assign Eka       = Bka ^ ((~Bke) & Bki);

  assign Amu_wire = Amu ^ Du;        assign Bko = rolx(Amu_wire,  8);
  assign Eke       = Bke ^ ((~Bki) & Bko);

  assign Asa_wire = Asa ^ Da;        assign Bku = rolx(Asa_wire, 18);
  assign Eki       = Bki ^ ((~Bko) & Bku);

  assign Eko       = Bko ^ ((~Bku) & Bka);
  assign Eku       = Bku ^ ((~Bka) & Bke);

  assign Abu_wire = Abu ^ Du;        assign Bma = rolx(Abu_wire, 27);
  assign Aga_wire = Aga ^ Da;        assign Bme = rolx(Aga_wire, 36);
  assign Ake_wire = Ake ^ De;        assign Bmi = rolx(Ake_wire, 10);
  assign Ema       = Bma ^ ((~Bme) & Bmi);

  assign Ami_wire = Ami ^ Di;        assign Bmo = rolx(Ami_wire, 15);
  assign Eme       = Bme ^ ((~Bmi) & Bmo);

  assign Aso_wire = Aso ^ Do;        assign Bmu = rolx(Aso_wire, 56);
  assign Emi       = Bmi ^ ((~Bmo) & Bmu);

  assign Emo       = Bmo ^ ((~Bmu) & Bma);
  assign Emu       = Bmu ^ ((~Bma) & Bme);

  assign Abi_wire = Abi ^ Di;        assign Bsa = rolx(Abi_wire, 62);
  assign Ago_wire = Ago ^ Do;        assign Bse = rolx(Ago_wire, 55);
  assign Aku_wire = Aku ^ Du;        assign Bsi = rolx(Aku_wire, 39);
  assign Esa       = Bsa ^ ((~Bse) & Bsi);

  assign Ama_wire = Ama ^ Da;        assign Bso = rolx(Ama_wire, 41);
  assign Ese       = Bse ^ ((~Bsi) & Bso);

  assign Ase_wire = Ase ^ De;        assign Bsu = rolx(Ase_wire,  2);
  assign Esi       = Bsi ^ ((~Bso) & Bsu);
  assign Eso       = Bso ^ ((~Bsu) & Bsa);
  assign Esu       = Bsu ^ ((~Bsa) & Bse);

  //-----------------------------------------------------------------------------  
  // pack the 25 output lanes back into the 1600-bit state
  assign rout = {
    Eba, Ebe, Ebi, Ebo, Ebu,
    Ega, Ege, Egi, Ego, Egu,
    Eka, Eke, Eki, Eko, Eku,
    Ema, Eme, Emi, Emo, Emu,
    Esa, Ese, Esi, Eso, Esu
  };

endmodule
