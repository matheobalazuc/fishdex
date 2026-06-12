import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/fishdex_theme.dart';
import '../widgets/glass_card.dart';

// 0=fermé  1=ouvert  2=réglementé
const _C = 0;
const _O = 1;
const _R = 2;

class _Species {
  final String name;
  final String emoji;
  final List<int> months; // J F M A M J J A S O N D
  final String note;
  const _Species(this.name, this.emoji, this.months, this.note);
}

const _freshwater = <_Species>[
  _Species('Truite fario',   '🐠', [_C,_C,_O,_O,_O,_O,_O,_O,_O,_C,_C,_C], 'Ouverture 2e sam. mars · Fermeture 3e dim. sept.'),
  _Species('Truite arc-en-ciel', '🐠', [_C,_C,_O,_O,_O,_O,_O,_O,_O,_C,_C,_C], 'Mêmes dates que la truite fario'),
  _Species('Ombre commun',   '🐟', [_C,_C,_O,_O,_O,_O,_O,_O,_O,_C,_C,_C], 'Fermeture identique aux salmonidés'),
  _Species('Brochet',        '🐟', [_O,_C,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Fermeture en février · Taille min. 50 cm'),
  _Species('Sandre',         '🐟', [_O,_C,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Fermeture en février · Taille min. 40 cm'),
  _Species('Perche',         '🐡', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Pas de fermeture · Taille min. 15 cm'),
  _Species('Carpe commune',  '🐡', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Ouverte toute l\'année · Souvent No-kill'),
  _Species('Gardon',         '🐟', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Ouverte toute l\'année'),
  _Species('Brème',          '🐟', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Ouverte toute l\'année'),
  _Species('Tanche',         '🐡', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Ouverte toute l\'année'),
  _Species('Saumon atlantique','🐠',[_C,_C,_O,_O,_O,_O,_O,_O,_C,_C,_C,_C], 'Varie par bassin · Quota personnel strict'),
  _Species('Anguille',       '🐍', [_R,_R,_R,_R,_R,_R,_R,_R,_R,_R,_R,_R], '⚠️ Moratoire dans la plupart des départements'),
];

const _sea = <_Species>[
  _Species('Bar commun',     '🦈', [_R,_R,_R,_O,_O,_O,_O,_O,_O,_O,_O,_R], 'Min 42 cm · 3 poissons/j · Restriction dec-mars'),
  _Species('Daurade royale', '🐟', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Toute l\'année · Min 23 cm'),
  _Species('Lieu jaune',     '🐡', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Toute l\'année · Min 30 cm'),
  _Species('Maquereau',      '🐟', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Toute l\'année · Pas de taille min.'),
  _Species('Sole commune',   '🐡', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Toute l\'année · Min 24 cm (Atlantique)'),
  _Species('Thon rouge',     '🐟', [_C,_C,_C,_C,_C,_R,_R,_R,_R,_R,_C,_C], '⚠️ Quota strict · Brevet obligatoire en mer'),
  _Species('Mulet cabot',    '🐟', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Toute l\'année · Min 30 cm'),
  _Species('Rouget barbet',  '🐟', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Toute l\'année · Min 11 cm'),
  _Species('Lieu noir',      '🐡', [_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O,_O], 'Toute l\'année · Min 30 cm'),
];

const _monthLabels = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];

class FishingCalendarScreen extends StatelessWidget {
  const FishingCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _appBar(context),
          SliverToBoxAdapter(child: _legend()),
          SliverToBoxAdapter(child: _section('🏞️ Eau douce', _freshwater)),
          SliverToBoxAdapter(child: _section('🌊 Pêche en mer', _sea)),
          SliverToBoxAdapter(child: _disclaimer()),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  SliverAppBar _appBar(BuildContext context) => SliverAppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    pinned: true,
    elevation: 0,
    leading: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.pop(context),
      child: const Icon(CupertinoIcons.chevron_back, color: FishdexTheme.primary)),
    title: const Text('Calendrier de pêche',
      style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(height: 1, color: Colors.black.withOpacity(0.06))),
  );

  Widget _legend() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('France métropolitaine · Saisons officielles',
        style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 13)),
      const SizedBox(height: 10),
      Row(children: [
        _legendChip('Ouvert', FishdexTheme.mint),
        const SizedBox(width: 10),
        _legendChip('Réglementé', FishdexTheme.golden),
        const SizedBox(width: 10),
        _legendChip('Fermé', FishdexTheme.textTertiary),
      ]),
    ]),
  );

  Widget _legendChip(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 14, height: 14,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  ]);

  Widget _section(String title, List<_Species> list) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
          color: FishdexTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        GlassCard(child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(children: [
            // Header months
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const SizedBox(width: 36),
                Expanded(child: Row(
                  children: _monthLabels.map((m) => Expanded(child: Center(
                    child: Text(m, style: const TextStyle(
                      color: FishdexTheme.textTertiary, fontSize: 8, fontWeight: FontWeight.w600))))).toList())),
              ]),
            ),
            ...list.map((s) => _speciesRow(s)),
          ]),
        )),
      ]),
    );
  }

  Widget _speciesRow(_Species s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 36, child: Text(s.emoji, style: const TextStyle(fontSize: 18))),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(
              color: FishdexTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            Row(children: s.months.asMap().entries.map((e) {
              final status = e.value;
              final color  = status == _O ? FishdexTheme.mint
                           : status == _R ? FishdexTheme.golden
                           : Colors.black.withOpacity(0.10);
              final isFirst = e.key == 0;
              final isLast  = e.key == 11;
              final same    = e.key < 11 && s.months[e.key + 1] == status;
              return Expanded(child: Container(
                height: 12,
                margin: const EdgeInsets.only(top: 3, right: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.horizontal(
                    left:  isFirst ? const Radius.circular(3) : Radius.zero,
                    right: isLast  ? const Radius.circular(3) : Radius.zero),
                ),
              ));
            }).toList()),
          ])),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 36, top: 2),
          child: Text(s.note,
            style: const TextStyle(color: FishdexTheme.textTertiary, fontSize: 10)),
        ),
        Divider(height: 12, color: Colors.black.withOpacity(0.04)),
      ]),
    );
  }

  Widget _disclaimer() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FishdexTheme.golden.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FishdexTheme.golden.withOpacity(0.25))),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('⚠️', style: TextStyle(fontSize: 18)),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vérifier la réglementation locale',
            style: TextStyle(color: FishdexTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            'Les dates peuvent varier selon le département et le cours d\'eau. '
            'Consultez toujours votre fédération de pêche locale (AAPPMA) '
            'ou le site www.federationpeche.fr pour les informations officielles.',
            style: TextStyle(color: FishdexTheme.textSecondary, fontSize: 11)),
        ])),
      ]),
    ),
  );
}
